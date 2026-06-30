package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.model.Category;
import com.sevalink.sevalinkbackend.dto.SearchSuggestion;
import com.sevalink.sevalinkbackend.repository.SearchRepository;
import com.sevalink.sevalinkbackend.repository.CategoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class SearchService {

    @Autowired
    private SearchRepository searchRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    // Maps frontend uppercase category values → DB canonical names
    private static final Map<String, String> CATEGORY_ALIAS = Map.of(
            "electrician",  "Electrical",
            "electrical",   "Electrical",
            "plumber",      "Plumbing",
            "plumbing",     "Plumbing",
            "carpenter",    "Carpentry",
            "carpentry",    "Carpentry",
            "painter",      "Painting",
            "painting",     "Painting",
            "cleaner",      "Cleaning",
            "cleaning",     "Cleaning"
    );

    // Secondary alias map for categories that don't fit in Map.of() (10-entry limit)
    private static final Map<String, String> CATEGORY_ALIAS_EXT = Map.of(
            "mechanic",     "Mechanic",
            "gardener",     "Gardener",
            "gardening",    "Gardener",
            "technician",   "Technician"
    );

    /** Normalise a raw category value sent from the client app to the DB name. */
    private String normalizeCategory(String raw) {
        if (raw == null) return null;
        String key = raw.trim().toLowerCase();
        String normalized = CATEGORY_ALIAS.get(key);
        if (normalized == null) normalized = CATEGORY_ALIAS_EXT.get(key);
        // Fall back to capitalized original value if no alias found
        return (normalized != null) ? normalized : capitalize(raw.trim());
    }

    private String capitalize(String s) {
        if (s == null || s.isEmpty()) return s;
        return Character.toUpperCase(s.charAt(0)) + s.substring(1).toLowerCase();
    }

    /**
     * Attempts to infer a canonical category name from a free-text keyword.
     * Returns null if no category match is found.
     * Side-effect: returns the remaining keyword (after stripping the alias) via
     * the single-element String array kwHolder (index 0).
     */
    private String inferCategoryFromKeyword(String kw, String[] kwHolder) {
        String lowercaseKw = kw.toLowerCase();
        // Check primary alias map
        for (Map.Entry<String, String> entry : CATEGORY_ALIAS.entrySet()) {
            String alias = entry.getKey();
            if (lowercaseKw.equals(alias)) {
                kwHolder[0] = "";
                return entry.getValue();
            } else if (lowercaseKw.contains(alias)) {
                kwHolder[0] = kw.replaceAll("(?i)\\b" + alias + "\\b", "").trim();
                return entry.getValue();
            }
        }
        // Check extension alias map
        for (Map.Entry<String, String> entry : CATEGORY_ALIAS_EXT.entrySet()) {
            String alias = entry.getKey();
            if (lowercaseKw.equals(alias)) {
                kwHolder[0] = "";
                return entry.getValue();
            } else if (lowercaseKw.contains(alias)) {
                kwHolder[0] = kw.replaceAll("(?i)\\b" + alias + "\\b", "").trim();
                return entry.getValue();
            }
        }
        return null;
    }

    // Basic keyword search
    public List<Worker> search(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return searchRepository.findAll();
        }

        String[] kwHolder = { keyword.trim() };
        String inferredCategory = inferCategoryFromKeyword(kwHolder[0], kwHolder);

        if (inferredCategory != null) {
            if (kwHolder[0].isEmpty()) {
                return searchRepository.searchByCategory(inferredCategory);
            } else {
                return searchRepository.searchWithoutLocation(kwHolder[0], inferredCategory, null);
            }
        }

        return searchRepository.searchByKeyword(kwHolder[0]);
    }

    // Category filter
    public List<Worker> searchByCategory(String categoryName) {
        return searchRepository.searchByCategory(normalizeCategory(categoryName));
    }

    // Availability filter
    public List<Worker> searchByAvailability(Boolean available) {
        return searchRepository.findByIsAvailableOrderByRatingDesc(available);
    }

    // Location based search
    public List<Worker> searchByLocation(Double lat, Double lng, Double radiusKm) {
        // Default radius 10km if not provided
        double radius = (radiusKm != null) ? radiusKm : 10.0;
        return searchRepository.searchByLocation(lat, lng, radius);
    }

    // Full search — all filters combined, sorted nearest first when coords provided
    public List<Worker> fullSearch(String keyword,
                                   String categoryName,
                                   Boolean available,
                                   Double lat,
                                   Double lng,
                                   Double radiusKm) {

        String[] kwHolder = { (keyword == null || keyword.trim().isEmpty()) ? "" : keyword.trim() };
        String normalizedCategory = normalizeCategory(categoryName);
        double radius = (radiusKm != null) ? radiusKm : 50.0;

        // If no category filter is explicitly selected, try to infer it from the keyword
        if (normalizedCategory == null && !kwHolder[0].isEmpty()) {
            normalizedCategory = inferCategoryFromKeyword(kwHolder[0], kwHolder);
        }

        if (lat == null || lng == null) {
            return searchRepository.searchWithoutLocation(kwHolder[0], normalizedCategory, available);
        }

        // Try location-based search first (sorted by proximity)
        List<Worker> locationResults = searchRepository.fullSearch(
                kwHolder[0], normalizedCategory, available, lat, lng, radius);

        // If no workers have GPS coordinates or none are within radius, fall back
        // to showing all matching workers sorted by rating
        if (locationResults.isEmpty()) {
            return searchRepository.searchWithoutLocation(kwHolder[0], normalizedCategory, available);
        }

        return locationResults;
    }

    public List<SearchSuggestion> getSuggestions(String query) {
        List<SearchSuggestion> suggestions = new ArrayList<>();
        if (query == null || query.trim().isEmpty()) {
            return suggestions;
        }
        
        String cleanQuery = query.trim().toLowerCase();
        Set<String> addedTexts = new HashSet<>();

        // 1. Check matching categories
        List<Category> matchingCategories = categoryRepository.findByNameContainingIgnoreCase(cleanQuery);
        for (Category cat : matchingCategories) {
            String catName = cat.getName();
            if (addedTexts.add(catName.toLowerCase())) {
                suggestions.add(new SearchSuggestion(catName, "CATEGORY"));
            }
        }

        // 2. Check matching worker names
        List<String> matchingWorkerNames = searchRepository.findMatchingWorkerNames(cleanQuery);
        for (String name : matchingWorkerNames) {
            if (name != null && addedTexts.add(name.toLowerCase())) {
                suggestions.add(new SearchSuggestion(name, "WORKER"));
            }
        }

        // 3. Check matching skills
        List<String> matchingSkillsRaw = searchRepository.findMatchingSkills(cleanQuery);
        for (String skillsList : matchingSkillsRaw) {
            if (skillsList != null) {
                // Split by comma
                String[] parts = skillsList.split(",");
                for (String part : parts) {
                    String skill = part.trim();
                    if (!skill.isEmpty() && skill.toLowerCase().contains(cleanQuery)) {
                        if (addedTexts.add(skill.toLowerCase())) {
                            suggestions.add(new SearchSuggestion(skill, "SKILL"));
                        }
                    }
                }
            }
        }

        // Limit to top 8 suggestions
        return suggestions.stream().limit(8).collect(Collectors.toList());
    }
}