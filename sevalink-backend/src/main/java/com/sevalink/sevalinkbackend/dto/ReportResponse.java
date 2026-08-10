package com.sevalink.sevalinkbackend.dto;

import com.sevalink.sevalinkbackend.model.Report;
import com.sevalink.sevalinkbackend.model.ReportStatus;
import com.sevalink.sevalinkbackend.model.ReportType;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ReportResponse {

    private Long id;

    // Reporter info (safe subset)
    private Long reporterId;
    private String reporterName;
    private String reporterEmail;

    // Reported user info (safe subset)
    private Long reportedUserId;
    private String reportedUserName;
    private String reportedUserEmail;

    // Related job (if any)
    private Long jobId;
    private String jobTitle;

    private ReportType reportType;
    private String description;
    private String evidence;

    private ReportStatus status;
    private String adminNote;
    private String actionTaken;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /**
     * Static factory — converts Report entity to safe DTO.
     * Avoids lazy-loading surprises by only reading what was already fetched.
     */
    public static ReportResponse from(Report report) {
        ReportResponse dto = new ReportResponse();

        dto.setId(report.getId());

        dto.setReporterId(report.getReporter().getId());
        dto.setReporterName(report.getReporter().getFullName());
        dto.setReporterEmail(report.getReporter().getEmail());

        dto.setReportedUserId(report.getReportedUser().getId());
        dto.setReportedUserName(report.getReportedUser().getFullName());
        dto.setReportedUserEmail(report.getReportedUser().getEmail());

        if (report.getRelatedJob() != null) {
            dto.setJobId(report.getRelatedJob().getId());
            dto.setJobTitle(report.getRelatedJob().getTitle());
        }

        dto.setReportType(report.getReportType());
        dto.setDescription(report.getDescription());
        dto.setEvidence(report.getEvidence());
        dto.setStatus(report.getStatus());
        dto.setAdminNote(report.getAdminNote());
        dto.setActionTaken(report.getActionTaken());
        dto.setCreatedAt(report.getCreatedAt());
        dto.setUpdatedAt(report.getUpdatedAt());

        return dto;
    }
}
