package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.Worker;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface SearchRepository extends JpaRepository<Worker, Long> {

    //  Search by keyword (category name, bio, worker name)
    @Query("SELECT w FROM Worker w WHERE " +
            "LOWER(w.category.name) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.bio) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.user.fullName) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
            "ORDER BY w.rating DESC")
    List<Worker> searchByKeyword(@Param("keyword") String keyword);

    //  Filter by category only
    @Query("SELECT w FROM Worker w WHERE " +
            "LOWER(w.category.name) = LOWER(:categoryName) " +
            "ORDER BY w.rating DESC")
    List<Worker> searchByCategory(@Param("categoryName") String categoryName);

    //  Filter by availability only
    List<Worker> findByIsAvailableOrderByRatingDesc(Boolean isAvailable);

    //  Keyword + availability
    @Query("SELECT w FROM Worker w WHERE " +
            "(LOWER(w.category.name) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.bio) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.user.fullName) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
            "AND w.isAvailable = :available " +
            "ORDER BY w.rating DESC")
    List<Worker> searchByKeywordAndAvailability(
            @Param("keyword") String keyword,
            @Param("available") Boolean available);

    //  Category + availability
    @Query("SELECT w FROM Worker w WHERE " +
            "LOWER(w.category.name) = LOWER(:categoryName) " +
            "AND w.isAvailable = :available " +
            "ORDER BY w.rating DESC")
    List<Worker> searchByCategoryAndAvailability(
            @Param("categoryName") String categoryName,
            @Param("available") Boolean available);

    //  Location based search (within radius in km) — sorted nearest first
    @Query("SELECT w FROM Worker w WHERE " +
            "(6371 * acos(cos(radians(:lat)) * cos(radians(w.latitude)) * " +
            "cos(radians(w.longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(w.latitude)))) < :radiusKm " +
            "ORDER BY " +
            "(6371 * acos(cos(radians(:lat)) * cos(radians(w.latitude)) * " +
            "cos(radians(w.longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(w.latitude)))) ASC")
    List<Worker> searchByLocation(
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusKm") Double radiusKm);

    //  Full search — keyword + category + availability + location (nearest first)
    @Query("SELECT w FROM Worker w WHERE " +
            "(:keyword = '' OR LOWER(w.category.name) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.bio) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.user.fullName) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
            "AND (:categoryName IS NULL OR LOWER(w.category.name) = LOWER(:categoryName)) " +
            "AND (:available IS NULL OR w.isAvailable = :available) " +
            "AND (w.latitude IS NOT NULL AND w.longitude IS NOT NULL) " +
            "AND (6371 * acos(cos(radians(:lat)) * cos(radians(w.latitude)) * " +
            "cos(radians(w.longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(w.latitude)))) < :radiusKm " +
            "ORDER BY " +
            "(6371 * acos(cos(radians(:lat)) * cos(radians(w.latitude)) * " +
            "cos(radians(w.longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(w.latitude)))) ASC")
    List<Worker> fullSearch(
            @Param("keyword") String keyword,
            @Param("categoryName") String categoryName,
            @Param("available") Boolean available,
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusKm") Double radiusKm);

    //  Full search WITHOUT location — keyword is optional (empty string = match all)
    @Query("SELECT w FROM Worker w WHERE " +
            "(:keyword = '' OR LOWER(w.category.name) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.bio) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(w.user.fullName) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
            "AND (:categoryName IS NULL OR LOWER(w.category.name) = LOWER(:categoryName)) " +
            "AND (:available IS NULL OR w.isAvailable = :available) " +
            "ORDER BY w.rating DESC")
    List<Worker> searchWithoutLocation(
            @Param("keyword") String keyword,
            @Param("categoryName") String categoryName,
            @Param("available") Boolean available);

    @Query("SELECT DISTINCT w.user.fullName FROM Worker w WHERE LOWER(w.user.fullName) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<String> findMatchingWorkerNames(@Param("query") String query);

    @Query("SELECT DISTINCT w.skills FROM Worker w WHERE w.skills IS NOT NULL AND LOWER(w.skills) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<String> findMatchingSkills(@Param("query") String query);
}