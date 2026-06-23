package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.service.WorkerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/workers")
@CrossOrigin(origins = "*")
public class WorkerController {

    @Autowired
    private WorkerService workerService;

    // Get all workers
    // GET http://localhost:8080/api/workers
    @GetMapping
    public List<Worker> getAllWorkers() {
        return workerService.getAllWorkers();
    }

    // Search workers by keyword
    // GET http://localhost:8080/api/workers/search?keyword=plumber
    @GetMapping("/search")
    public List<Worker> searchWorkers(@RequestParam String keyword) {
        return workerService.searchWorkers(keyword);
    }

    // Get available workers only
    // GET http://localhost:8080/api/workers/available
    @GetMapping("/available")
    public List<Worker> getAvailableWorkers() {
        return workerService.getAvailableWorkers();
    }

    // Get worker by ID
    // GET http://localhost:8080/api/workers/1
    @GetMapping("/{id}")
    public ResponseEntity<?> getWorkerById(@PathVariable Long id) {
        return workerService.getWorkerById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Update availability
    // PUT http://localhost:8080/api/workers/1/availability?status=true
    @PutMapping("/{id}/availability")
    public ResponseEntity<?> updateAvailability(@PathVariable Long id,
                                                @RequestParam Boolean status) {
        try {
            Worker updated = workerService.updateAvailability(id, status);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}
