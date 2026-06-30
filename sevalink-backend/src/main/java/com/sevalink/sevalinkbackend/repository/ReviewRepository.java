package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Long> {
    List<Review> findByWorkerIdOrderByCreatedAtDesc(Long workerId);
    Optional<Review> findByClientIdAndJobPostId(Long clientId, Long jobPostId);
}
