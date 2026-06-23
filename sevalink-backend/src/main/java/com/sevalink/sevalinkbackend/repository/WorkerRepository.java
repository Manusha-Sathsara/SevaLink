package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.Worker;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface WorkerRepository extends JpaRepository<Worker, Long> {

    // Search workers by category name
    List<Worker> findByCategoryNameContainingIgnoreCase(String categoryName);

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
}
