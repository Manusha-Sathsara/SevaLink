package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.repository.SearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class SearchService {

    @Autowired
    private SearchRepository searchRepository;

    // Basic keyword search
    public List<Worker> search(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return searchRepository.findAll();
        }
        return searchRepository.searchByKeyword(keyword.trim());
    }

    // Category filter
    public List<Worker> searchByCategory(String categoryName) {
        return searchRepository.searchByCategory(categoryName);
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

    // Full search — all filters combined
    public List<Worker> fullSearch(String keyword,
                                   String categoryName,
                                   Boolean available,
                                   Double lat,
                                   Double lng,
                                   Double radiusKm) {

        // If no keyword, use empty string to match all
        String kw = (keyword == null || keyword.trim().isEmpty()) ? "" : keyword.trim();
        double radius = (radiusKm != null) ? radiusKm : 10.0;

        return searchRepository.fullSearch(kw, categoryName, available, lat, lng, radius);
    }
}