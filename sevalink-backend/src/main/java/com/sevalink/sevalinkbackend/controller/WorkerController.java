package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.dto.AdminWorkerDto;
import com.sevalink.sevalinkbackend.dto.UpdateWorkerProfileRequest;
import com.sevalink.sevalinkbackend.dto.ApiResponse;
import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.model.WorkerStatus;
import com.sevalink.sevalinkbackend.service.WorkerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/workers")
@CrossOrigin(origins = "*")
public class WorkerController {

    @Autowired
    private WorkerService workerService;

    // Get current authenticated worker's own profile
    // GET http://localhost:8080/api/workers/me
    @GetMapping("/me")
    public ResponseEntity<?> getMyWorkerProfile() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String email = auth.getName();
            Worker worker = workerService.getWorkerByEmail(email);
            // Return minimal safe map - just id and userId
            return ResponseEntity.ok(Map.of(
                "id", worker.getId(),
                "userId", worker.getUser().getId(),
                "isAvailable", worker.getIsAvailable() != null && worker.getIsAvailable()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Get all workers
    // GET http://localhost:8080/api/workers
    @GetMapping
    public List<Worker> getAllWorkers() {
        return workerService.getAllWorkers();
    }

    // Get all workers for admin verification
    // GET http://localhost:8080/api/workers/admin
    @GetMapping("/admin")
    public ResponseEntity<ApiResponse<List<AdminWorkerDto>>> getAdminWorkers() {
        List<AdminWorkerDto> workers = workerService.getAllWorkerDtos();
        return ResponseEntity.ok(ApiResponse.success("Worker list loaded", workers));
    }

    // Update worker verification status
    // PUT http://localhost:8080/api/workers/{id}/status
    @PutMapping("/{id}/status")
    public ResponseEntity<ApiResponse<AdminWorkerDto>> updateWorkerStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> payload) {
        try {
            String statusValue = payload.get("status");
            WorkerStatus status = WorkerStatus.valueOf(statusValue.toUpperCase());
            AdminWorkerDto updated = workerService.updateWorkerStatus(id, status);
            return ResponseEntity.ok(ApiResponse.success("Worker status updated", updated));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Invalid status value"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
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

    // Update profile
    // PUT http://localhost:8080/api/workers/1/profile
    @PutMapping("/{id}/profile")
    public ResponseEntity<?> updateWorkerProfile(@PathVariable Long id,
                                                 @RequestBody UpdateWorkerProfileRequest request) {
        try {
            Worker updated = workerService.updateWorkerProfile(id, request);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Upload profile image
    // POST http://localhost:8080/api/workers/1/profile/image
    @PostMapping("/{id}/profile/image")
    public ResponseEntity<?> uploadProfileImage(@PathVariable Long id,
                                                @RequestParam("file") MultipartFile file) {
        try {
            Worker updated = workerService.uploadProfileImage(id, file);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Update worker live location
    // PUT http://localhost:8080/api/workers/1/location?latitude=6.9&longitude=79.8
    @PutMapping("/{id}/location")
    public ResponseEntity<?> updateWorkerLocation(
            @PathVariable Long id,
            @RequestParam Double latitude,
            @RequestParam Double longitude) {
        try {
            Worker updated = workerService.updateWorkerLocation(id, latitude, longitude);
            return ResponseEntity.ok(updated);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}
