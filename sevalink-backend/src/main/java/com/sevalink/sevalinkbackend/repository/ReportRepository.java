package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.Report;
import com.sevalink.sevalinkbackend.model.ReportStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReportRepository extends JpaRepository<Report, Long> {

    // All reports submitted by a specific reporter (for user's "my reports" view)
    List<Report> findByReporterIdOrderByCreatedAtDesc(Long reporterId);

    // All reports targeting a specific user (admin use)
    List<Report> findByReportedUserIdOrderByCreatedAtDesc(Long reportedUserId);

    // All reports (admin view), ordered newest first
    List<Report> findAllByOrderByCreatedAtDesc();

    // Admin: filter by status
    List<Report> findByStatusOrderByCreatedAtDesc(ReportStatus status);
}
