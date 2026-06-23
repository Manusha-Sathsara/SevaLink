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

    List<JobPost> findByStatusOrderByCreatedAtDesc(String status);

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
}
