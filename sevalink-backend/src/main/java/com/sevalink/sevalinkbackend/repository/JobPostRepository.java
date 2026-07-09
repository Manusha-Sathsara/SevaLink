package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.JobPost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface JobPostRepository extends JpaRepository<JobPost, Long> {

    List<JobPost> findByClientIdOrderByCreatedAtDesc(Long clientId);
    List<JobPost> findByClientIdAndStatusNotOrderByCreatedAtDesc(Long clientId, String status);

    List<JobPost> findByStatusOrderByCreatedAtDesc(String status);

    // Open jobs matching a specific category — for worker feed filtering
    List<JobPost> findByStatusAndCategoryIdOrderByCreatedAtDesc(String status, Long categoryId);

    @Query("SELECT j FROM JobPost j WHERE " +
            "j.status = 'OPEN' AND " +
            "(6371 * acos(cos(radians(:lat)) * cos(radians(j.latitude)) * " +
            "cos(radians(j.longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(j.latitude)))) < :radiusKm " +
            "ORDER BY j.createdAt DESC")
    List<JobPost> findNearbyJobs(
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusKm") Double radiusKm);

    @Query("SELECT j FROM JobPost j WHERE " +
            "j.status = 'OPEN' AND " +
            "j.category.id = :categoryId AND " +
            "(6371 * acos(cos(radians(:lat)) * cos(radians(j.latitude)) * " +
            "cos(radians(j.longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(j.latitude)))) < :radiusKm " +
            "ORDER BY j.createdAt DESC")
    List<JobPost> findNearbyJobsByCategory(
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusKm") Double radiusKm,
            @Param("categoryId") Long categoryId);

    long countByClientId(Long clientId);
    long countByClientIdAndStatusNot(Long clientId, String status);
    long countByClientIdAndStatus(Long clientId, String status);
    List<JobPost> findByClientIdAndStatusInOrderByCreatedAtDesc(Long clientId, List<String> statuses);

    // ── Worker-filtered feed: exclude jobs where the worker already has a quotation ──

    @Query("SELECT j FROM JobPost j WHERE " +
            "j.status = 'OPEN' AND " +
            "NOT EXISTS (SELECT q FROM Quotation q WHERE q.jobPost = j AND q.worker.id = :workerId) " +
            "ORDER BY j.createdAt DESC")
    List<JobPost> findOpenJobsExcludingWorkerQuotes(
            @Param("workerId") Long workerId);

    @Query("SELECT j FROM JobPost j WHERE " +
            "j.status = 'OPEN' AND " +
            "j.category.id = :categoryId AND " +
            "NOT EXISTS (SELECT q FROM Quotation q WHERE q.jobPost = j AND q.worker.id = :workerId) " +
            "ORDER BY j.createdAt DESC")
    List<JobPost> findOpenJobsByCategoryExcludingWorkerQuotes(
            @Param("categoryId") Long categoryId,
            @Param("workerId") Long workerId);

    @Query("SELECT j FROM JobPost j WHERE " +
            "j.status = 'OPEN' AND " +
            "NOT EXISTS (SELECT q FROM Quotation q WHERE q.jobPost = j AND q.worker.id = :workerId) AND " +
            "(6371 * acos(cos(radians(:lat)) * cos(radians(j.latitude)) * " +
            "cos(radians(j.longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(j.latitude)))) < :radiusKm " +
            "ORDER BY j.createdAt DESC")
    List<JobPost> findNearbyJobsExcludingWorkerQuotes(
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusKm") Double radiusKm,
            @Param("workerId") Long workerId);

    @Query("SELECT j FROM JobPost j WHERE " +
            "j.status = 'OPEN' AND " +
            "j.category.id = :categoryId AND " +
            "NOT EXISTS (SELECT q FROM Quotation q WHERE q.jobPost = j AND q.worker.id = :workerId) AND " +
            "(6371 * acos(cos(radians(:lat)) * cos(radians(j.latitude)) * " +
            "cos(radians(j.longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(j.latitude)))) < :radiusKm " +
            "ORDER BY j.createdAt DESC")
    List<JobPost> findNearbyJobsByCategoryExcludingWorkerQuotes(
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusKm") Double radiusKm,
            @Param("categoryId") Long categoryId,
            @Param("workerId") Long workerId);
}
