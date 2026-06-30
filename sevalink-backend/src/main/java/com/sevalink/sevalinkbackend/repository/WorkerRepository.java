package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.model.WorkerStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface WorkerRepository extends JpaRepository<Worker, Long> {

    // Find worker by user ID
    Optional<Worker> findByUserId(Long userId);

    // Search workers by category name
    List<Worker> findByCategoryNameContainingIgnoreCase(String categoryName);

    // Find workers by verification status
    List<Worker> findByStatus(WorkerStatus status);

    // Count workers by verification status
    long countByStatus(WorkerStatus status);

    // Find available workers only
    List<Worker> findByIsAvailableTrue();

    // Search by category and availability
    List<Worker> findByCategoryNameContainingIgnoreCaseAndIsAvailableTrue(String categoryName);

    // Custom search query
    @Query("SELECT w FROM Worker w WHERE " +
            "LOWER(w.category.name) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
            "AND w.isAvailable = true " +
            "ORDER BY w.rating DESC")
    List<Worker> searchWorkers(@Param("keyword") String keyword);

    // Get Top Rated Workers for Dashboard
    List<Worker> findTop10ByIsAvailableTrueOrderByRatingDesc();

    // Find nearby available workers
    @Query("SELECT w FROM Worker w WHERE " +
            "w.isAvailable = true AND " +
            "w.latitude IS NOT NULL AND w.longitude IS NOT NULL AND " +
            "(6371 * acos(cos(radians(:lat)) * cos(radians(w.latitude)) * " +
            "cos(radians(w.longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(w.latitude)))) < :radiusKm")
    List<Worker> findNearbyWorkers(
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusKm") Double radiusKm);

    // Find nearby available workers whose category matches the job's category
    @Query("SELECT w FROM Worker w WHERE " +
            "w.isAvailable = true AND " +
            "w.category.id = :categoryId AND " +
            "w.latitude IS NOT NULL AND w.longitude IS NOT NULL AND " +
            "(6371 * acos(cos(radians(:lat)) * cos(radians(w.latitude)) * " +
            "cos(radians(w.longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(w.latitude)))) < :radiusKm")
    List<Worker> findNearbyWorkersByCategory(
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusKm") Double radiusKm,
            @Param("categoryId") Long categoryId);
}
