package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.service.SearchService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/search")
@CrossOrigin(origins = "*")
public class SearchController {

    @Autowired
    private SearchService searchService;

    // 1. Keyword search
    // GET /api/search?keyword=plumber
    @GetMapping
    public List<Worker> search(@RequestParam(required = false) String keyword) {
        return searchService.search(keyword);
    }

    // 2. Category filter
    // GET /api/search/category?name=Plumbing
    @GetMapping("/category")
    public List<Worker> searchByCategory(@RequestParam String name) {
        return searchService.searchByCategory(name);
    }

    // 3. Availability filter
    // GET /api/search/available?status=true
    @GetMapping("/available")
    public List<Worker> searchByAvailability(@RequestParam Boolean status) {
        return searchService.searchByAvailability(status);
    }

    // 4. Location based search
    // GET /api/search/nearby?lat=6.9271&lng=79.8612&radius=5
    @GetMapping("/nearby")
    public List<Worker> searchByLocation(@RequestParam Double lat,
                                         @RequestParam Double lng,
                                         @RequestParam(required = false) Double radius) {
        return searchService.searchByLocation(lat, lng, radius);
    }

    // 5. Full search — all filters at once (main search bar endpoint)
    // GET /api/search/full?keyword=plumber&category=Plumbing&available=true&lat=6.9271&lng=79.8612&radius=5
    @GetMapping("/full")
    public List<Worker> fullSearch(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Boolean available,
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng,
            @RequestParam(required = false) Double radius) {
        return searchService.fullSearch(keyword, category, available, lat, lng, radius);
    }
}