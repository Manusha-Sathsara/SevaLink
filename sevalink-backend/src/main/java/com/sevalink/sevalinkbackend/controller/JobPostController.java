package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.model.JobPost;
import com.sevalink.sevalinkbackend.model.JobTimeline;
import com.sevalink.sevalinkbackend.service.JobPostService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/jobs")
@CrossOrigin(origins = "*")
public class JobPostController {

    @Autowired
    private JobPostService jobPostService;

    // Client posts a new job
    // POST http://localhost:8080/api/jobs
    @PostMapping
    public ResponseEntity<?> createJob(@RequestBody JobPost jobPost) {
        try {
            JobPost saved = jobPostService.createJob(jobPost);
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // Worker sees all open jobs
    // GET http://localhost:8080/api/jobs
    @GetMapping
    public List<JobPost> getAllOpenJobs() {
        return jobPostService.getAllOpenJobs();
    }

    // Worker sees nearby jobs
    // GET http://localhost:8080/api/jobs/nearby?lat=6.9271&lng=79.8612&radius=10
    @GetMapping("/nearby")
    public List<JobPost> getNearbyJobs(
            @RequestParam Double lat,
            @RequestParam Double lng,
            @RequestParam(required = false) Double radius) {
        return jobPostService.getNearbyJobs(lat, lng, radius);
    }

    // Worker sees nearby jobs by category
    // GET http://localhost:8080/api/jobs/nearby/category?lat=6.9&lng=79.8&radius=10&categoryId=1
    @GetMapping("/nearby/category")
    public List<JobPost> getNearbyJobsByCategory(
            @RequestParam Double lat,
            @RequestParam Double lng,
            @RequestParam(required = false) Double radius,
            @RequestParam Long categoryId) {
        return jobPostService.getNearbyJobsByCategory(lat, lng, radius, categoryId);
    }

    // Get job by ID
// GET http://localhost:8080/api/jobs/detail/1
    @GetMapping("/detail/{id}")
    public ResponseEntity<?> getJobById(@PathVariable Long id) {
        return jobPostService.getJobById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Client sees their own jobs
    // GET http://localhost:8080/api/jobs/client/1
    @GetMapping("/client/{clientId}")
    public List<JobPost> getClientJobs(@PathVariable Long clientId) {
        return jobPostService.getClientJobs(clientId);
    }

    // Cancel a job
    // PUT http://localhost:8080/api/jobs/1/cancel
    @PutMapping("/{id}/cancel")
    public ResponseEntity<?> cancelJob(@PathVariable Long id) {
        try {
            JobPost cancelled = jobPostService.cancelJob(id);
            return ResponseEntity.ok(cancelled);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // Get job timeline
    // GET http://localhost:8080/api/jobs/1/timeline
    @GetMapping("/detail/{id}/timeline")
    public List<JobTimeline> getJobTimeline(@PathVariable Long id) {
        return jobPostService.getJobTimeline(id);
    }

    // Update job timeline
    // PUT http://localhost:8080/api/jobs/1/timeline?status=WORKER_EN_ROUTE&note=On the way
    @PutMapping("/detail/{id}/timeline")
    public ResponseEntity<?> updateTimeline(
            @PathVariable Long id,
            @RequestParam String status,
            @RequestParam(required = false) String note) {
        try {
            JobTimeline timeline = jobPostService.updateTimeline(id, status, note);
            return ResponseEntity.ok(timeline);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
