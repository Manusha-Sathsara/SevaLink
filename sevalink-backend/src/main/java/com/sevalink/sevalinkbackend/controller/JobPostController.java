package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.model.JobPost;
import com.sevalink.sevalinkbackend.model.JobTimeline;
import com.sevalink.sevalinkbackend.service.JobPostService;
import com.sevalink.sevalinkbackend.dto.ClientJobStatsDto;
import com.sevalink.sevalinkbackend.dto.ClientJobDto;
import com.sevalink.sevalinkbackend.dto.ApiResponse;
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
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Worker sees all open jobs
    // GET http://localhost:8080/api/jobs
    @GetMapping
    public List<JobPost> getAllOpenJobs() {
        return jobPostService.getAllOpenJobs();
    }

    // Admin sees all jobs regardless of status
    // GET http://localhost:8080/api/jobs/admin
    @GetMapping("/admin")
    public List<JobPost> getAllJobsAdmin() {
        return jobPostService.getAllJobsAdmin();
    }

    // Update a job for admin management
    // PUT http://localhost:8080/api/jobs/{id}
    @PutMapping("/{id}")
    public ResponseEntity<?> updateJob(@PathVariable Long id, @RequestBody JobPost jobPost) {
        try {
            JobPost updated = jobPostService.updateJob(id, jobPost);
            return ResponseEntity.ok(updated);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Delete a job for admin management
    // DELETE http://localhost:8080/api/jobs/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteJob(@PathVariable Long id) {
        try {
            jobPostService.deleteJob(id);
            return ResponseEntity.ok(ApiResponse.success("Job deleted", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Worker feed — alias for getAllOpenJobs (used by worker app UI)
    // GET http://localhost:8080/api/jobs/feed
    @GetMapping("/feed")
    public List<JobPost> getWorkerFeed() {
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

    // Worker feed nearby — alias for getNearbyJobs
    // GET http://localhost:8080/api/jobs/feed/nearby?lat=6.9271&lng=79.8612&radius=10
    @GetMapping("/feed/nearby")
    public List<JobPost> getFeedNearby(
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
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
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
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Client job stats
    // GET http://localhost:8080/api/jobs/client/1/stats
    @GetMapping("/client/{clientId}/stats")
    public ResponseEntity<?> getClientJobStats(@PathVariable Long clientId) {
        try {
            ClientJobStatsDto stats = jobPostService.getClientJobStats(clientId);
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Client jobs with quote counts
    // GET http://localhost:8080/api/jobs/client/1/with-quotes?status=OPEN
    @GetMapping("/client/{clientId}/with-quotes")
    public ResponseEntity<?> getClientJobsWithQuotes(
            @PathVariable Long clientId,
            @RequestParam(required = false) String status) {
        try {
            List<ClientJobDto> jobs = jobPostService.getClientJobsWithQuotes(clientId, status);
            return ResponseEntity.ok(jobs);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Confirm payment (Client or Worker)
    // POST http://localhost:8080/api/jobs/1/confirm-payment
    @PostMapping("/{id}/confirm-payment")
    public ResponseEntity<?> confirmPayment(@PathVariable Long id) {
        try {
            // Determine caller email from Spring Security context
            org.springframework.security.core.Authentication auth =
                    org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal())) {
                return ResponseEntity.status(401).body(ApiResponse.error("Unauthorized"));
            }
            String email = auth.getName();
            JobPost updated = jobPostService.confirmPayment(id, email);
            return ResponseEntity.ok(updated);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // File a complaint
    // POST http://localhost:8080/api/jobs/1/complaint
    @PostMapping("/{id}/complaint")
    public ResponseEntity<?> fileComplaint(
            @PathVariable Long id,
            @RequestBody java.util.Map<String, String> body) {
        try {
            org.springframework.security.core.Authentication auth =
                    org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal())) {
                return ResponseEntity.status(401).body(ApiResponse.error("Unauthorized"));
            }
            String email = auth.getName();
            String description = body.getOrDefault("description", "");
            com.sevalink.sevalinkbackend.model.Complaint complaint =
                    jobPostService.fileComplaint(id, email, description);
            return ResponseEntity.ok(complaint);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Get assigned worker for a job (client tracking)
    // GET http://localhost:8080/api/jobs/1/assigned-worker
    @GetMapping("/{id}/assigned-worker")
    public ResponseEntity<?> getAssignedWorker(@PathVariable Long id) {
        try {
            com.sevalink.sevalinkbackend.model.Worker worker = jobPostService.getAssignedWorker(id);
            return ResponseEntity.ok(worker);
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
}
