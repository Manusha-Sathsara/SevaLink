package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.model.Review;
import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.repository.ReviewRepository;
import com.sevalink.sevalinkbackend.repository.WorkerRepository;
import com.sevalink.sevalinkbackend.dto.ApiResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/reviews")
@CrossOrigin(origins = "*")
public class ReviewController {

    @Autowired
    private ReviewRepository reviewRepository;

    @Autowired
    private WorkerRepository workerRepository;

    // Client submits a review
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
            worker.setRating(newRating);
            worker.setTotalReviews(currentReviews + 1);
            workerRepository.save(worker);
            
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // Get reviews for a worker
    @GetMapping("/worker/{workerId}")
    public List<Review> getWorkerReviews(@PathVariable Long workerId) {
        return reviewRepository.findByWorkerIdOrderByCreatedAtDesc(workerId);
    }
    
    // Check if client rated a job
    @GetMapping("/check")
    public ResponseEntity<?> checkReviewStatus(@RequestParam Long clientId, @RequestParam Long jobId) {
        boolean exists = reviewRepository.findByClientIdAndJobPostId(clientId, jobId).isPresent();
        return ResponseEntity.ok(java.util.Map.of("hasReviewed", exists));
    }
}
