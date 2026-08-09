package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.model.Review;
import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.repository.ReviewRepository;
import com.sevalink.sevalinkbackend.repository.WorkerRepository;
import com.sevalink.sevalinkbackend.service.FileStorageService;
import com.sevalink.sevalinkbackend.dto.ApiResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/reviews")
@CrossOrigin(origins = "*")
public class ReviewController {

    @Autowired
    private ReviewRepository reviewRepository;

    @Autowired
    private WorkerRepository workerRepository;

    @Autowired
    private FileStorageService fileStorageService;

    // Client submits a review
    // POST /api/reviews
    @PostMapping
    public ResponseEntity<?> submitReview(@RequestBody Review review) {
        try {
            if (reviewRepository.findByClientIdAndJobPostId(review.getClient().getId(), review.getJobPost().getId()).isPresent()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("You have already reviewed this job."));
            }
            
            Review saved = reviewRepository.save(review);
            
            // Update Worker average rating
            Worker worker = workerRepository.findById(review.getWorker().getId())
                    .orElseThrow(() -> new RuntimeException("Worker not found"));
            
            int currentReviews = worker.getTotalReviews() != null ? worker.getTotalReviews() : 0;
            double currentRating = worker.getRating() != null ? worker.getRating() : 0.0;
            
            double newRating = ((currentRating * currentReviews) + review.getRating()) / (currentReviews + 1);
            worker.setRating(Math.round(newRating * 10.0) / 10.0); // round to 1 decimal
            worker.setTotalReviews(currentReviews + 1);
            workerRepository.save(worker);
            
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Upload a review photo
    // POST /api/reviews/upload-photo
    @PostMapping("/upload-photo")
    public ResponseEntity<?> uploadReviewPhoto(@RequestParam("file") MultipartFile file) {
        try {
            String fileName = fileStorageService.storeFile(file);
            return ResponseEntity.ok(Map.of("fileName", fileName));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to upload photo: " + e.getMessage()));
        }
    }

    // Get reviews for a worker
    // GET /api/reviews/worker/{workerId}
    @GetMapping("/worker/{workerId}")
    public List<Review> getWorkerReviews(@PathVariable Long workerId) {
        return reviewRepository.findByWorkerIdOrderByCreatedAtDesc(workerId);
    }
    
    // Check if client rated a job
    // GET /api/reviews/check?clientId=X&jobId=Y
    @GetMapping("/check")
    public ResponseEntity<?> checkReviewStatus(@RequestParam Long clientId, @RequestParam Long jobId) {
        boolean exists = reviewRepository.findByClientIdAndJobPostId(clientId, jobId).isPresent();
        return ResponseEntity.ok(Map.of("hasReviewed", exists));
    }
}
