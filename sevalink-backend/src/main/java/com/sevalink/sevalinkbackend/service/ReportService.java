package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.ReportRequest;
import com.sevalink.sevalinkbackend.dto.ReportResponse;
import com.sevalink.sevalinkbackend.dto.ReportUpdateRequest;
import com.sevalink.sevalinkbackend.model.*;
import com.sevalink.sevalinkbackend.repository.JobPostRepository;
import com.sevalink.sevalinkbackend.repository.ReportRepository;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ReportService {

    @Autowired
    private ReportRepository reportRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JobPostRepository jobPostRepository;

    /**
     * USER: Submit a new report.
     * reporterEmail is resolved from the JWT token by the controller.
     */
    @Transactional
    public ReportResponse createReport(String reporterEmail, ReportRequest request) {

        // Resolve reporter from JWT email
        User reporter = userRepository.findByEmail(reporterEmail)
                .orElseThrow(() -> new RuntimeException("Reporter user not found"));

        // Resolve reported user
        User reportedUser = userRepository.findById(request.getReportedUserId())
                .orElseThrow(() -> new RuntimeException("Reported user not found"));

        // Prevent self-reporting
        if (reporter.getId() == reportedUser.getId()) {
            throw new RuntimeException("You cannot report yourself");
        }

        Report report = new Report();
        report.setReporter(reporter);
        report.setReportedUser(reportedUser);
        report.setReportType(request.getReportType());
        report.setDescription(request.getDescription());
        report.setEvidence(request.getEvidence());
        report.setStatus(ReportStatus.PENDING);

        // Optionally link to a job
        if (request.getJobId() != null) {
            JobPost job = jobPostRepository.findById(request.getJobId())
                    .orElseThrow(() -> new RuntimeException("Job not found"));
            report.setRelatedJob(job);
        }

        Report saved = reportRepository.save(report);
        return ReportResponse.from(saved);
    }

    /**
     * USER: Get all reports submitted by the logged-in user.
     */
    @Transactional(readOnly = true)
    public List<ReportResponse> getMyReports(String reporterEmail) {
        User reporter = userRepository.findByEmail(reporterEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return reportRepository.findByReporterIdOrderByCreatedAtDesc(reporter.getId())
                .stream()
                .map(ReportResponse::from)
                .collect(Collectors.toList());
    }

    /**
     * USER / ADMIN: Get a specific report by ID.
     * Users can only view their own reports; admins can view any.
     */
    @Transactional(readOnly = true)
    public ReportResponse getReportById(Long reportId, String requesterEmail, boolean isAdmin) {
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new RuntimeException("Report not found"));

        if (!isAdmin) {
            // Non-admin users can only view their own reports
            if (!report.getReporter().getEmail().equals(requesterEmail)) {
                throw new RuntimeException("Access denied");
            }
        }

        return ReportResponse.from(report);
    }

    /**
     * ADMIN: Get all reports, optionally filtered by status string.
     */
    @Transactional(readOnly = true)
    public List<ReportResponse> getAllReports(String statusFilter) {
        List<Report> reports;

        if (statusFilter != null && !statusFilter.isBlank()) {
            try {
                ReportStatus status = ReportStatus.valueOf(statusFilter.toUpperCase());
                reports = reportRepository.findByStatusOrderByCreatedAtDesc(status);
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid status filter: " + statusFilter);
            }
        } else {
            reports = reportRepository.findAllByOrderByCreatedAtDesc();
        }

        return reports.stream()
                .map(ReportResponse::from)
                .collect(Collectors.toList());
    }

    /**
     * ADMIN: Update a report's status, admin note, and/or action taken.
     */
    @Transactional
    public ReportResponse updateReport(Long reportId, ReportUpdateRequest request) {
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new RuntimeException("Report not found"));

        if (request.getStatus() != null) {
            report.setStatus(request.getStatus());
        }
        if (request.getAdminNote() != null) {
            report.setAdminNote(request.getAdminNote());
        }
        if (request.getActionTaken() != null) {
            report.setActionTaken(request.getActionTaken());
        }

        Report updated = reportRepository.save(report);
        return ReportResponse.from(updated);
    }
}
