package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.Worker;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface SearchRepository extends JpaRepository<Worker, Long> {

    // 1. Search by keyword (category name, bio, worker name)
    @Query("SELECT w FROM Worker w WHERE " +
            "LOWER(w.category.name) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.bio) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.user.name) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
            "ORDER BY w.rating DESC")
    List<Worker> searchByKeyword(@Param("keyword") String keyword);

    // 2. Filter by category only
    @Query("SELECT w FROM Worker w WHERE " +
            "LOWER(w.category.name) = LOWER(:categoryName) " +
            "ORDER BY w.rating DESC")
    List<Worker> searchByCategory(@Param("categoryName") String categoryName);

    // 3. Filter by availability only
    List<Worker> findByIsAvailableOrderByRatingDesc(Boolean isAvailable);

    // 4. Keyword + availability
    @Query("SELECT w FROM Worker w WHERE " +
            "(LOWER(w.category.name) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.bio) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.user.name) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
            "AND w.isAvailable = :available " +
            "ORDER BY w.rating DESC")
    List<Worker> searchByKeywordAndAvailability(
            @Param("keyword") String keyword,
            @Param("available") Boolean available);

    // 5. Category + availability
    @Query("SELECT w FROM Worker w WHERE " +
            "LOWER(w.category.name) = LOWER(:categoryName) " +
            "AND w.isAvailable = :available " +
            "ORDER BY w.rating DESC")
    List<Worker> searchByCategoryAndAvailability(
            @Param("categoryName") String categoryName,
            @Param("available") Boolean available);

    // 6. Location based search (within radius in km)
    @Query("SELECT w FROM Worker w WHERE " +
            "(6371 * acos(cos(radians(:lat)) * cos(radians(w.latitude)) * " +
            "cos(radians(w.longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(w.latitude)))) < :radiusKm " +
            "ORDER BY w.rating DESC")
    List<Worker> searchByLocation(
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusKm") Double radiusKm);

    // 7. Full search — keyword + category + availability + location
    @Query("SELECT w FROM Worker w WHERE " +
            "(LOWER(w.category.name) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.bio) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.user.name) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
            "AND (:categoryName IS NULL OR LOWER(w.category.name) = LOWER(:categoryName)) " +
            "AND (:available IS NULL OR w.isAvailable = :available) " +
            "AND (:lat IS NULL OR :lng IS NULL OR " +
            "(6371 * acos(cos(radians(:lat)) * cos(radians(w.latitude)) * " +
            "cos(radians(w.longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(w.latitude)))) < :radiusKm) " +
            "ORDER BY w.rating DESC")
    List<Worker> fullSearch(
            @Param("keyword") String keyword,
            @Param("categoryName") String categoryName,
            @Param("available") Boolean available,
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusKm") Double radiusKm);
}