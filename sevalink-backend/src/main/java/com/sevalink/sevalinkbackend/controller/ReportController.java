package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.dto.ApiResponse;
import com.sevalink.sevalinkbackend.dto.ReportRequest;
import com.sevalink.sevalinkbackend.dto.ReportResponse;
import com.sevalink.sevalinkbackend.dto.ReportUpdateRequest;
import com.sevalink.sevalinkbackend.service.ReportService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@CrossOrigin(origins = "*")
public class ReportController {

    @Autowired
    private ReportService reportService;

    // ============================================================
    // USER endpoints (any authenticated user — CLIENT or WORKER)
    // Mapped under /api/reports so SecurityConfig allows any auth role
    // ============================================================

    /**
     * POST /api/reports
     * Submit a new report against another user.
     */
    @PostMapping("/api/reports")
    public ResponseEntity<ApiResponse<ReportResponse>> createReport(
            @Valid @RequestBody ReportRequest request) {
        try {
            String email = getCurrentUserEmail();
            ReportResponse response = reportService.createReport(email, request);
            return ResponseEntity.ok(ApiResponse.success("Report submitted successfully", response));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * GET /api/reports/my
     * Get all reports submitted by the currently authenticated user.
     */
    @GetMapping("/api/reports/my")
    public ResponseEntity<ApiResponse<List<ReportResponse>>> getMyReports() {
        try {
            String email = getCurrentUserEmail();
            List<ReportResponse> reports = reportService.getMyReports(email);
            return ResponseEntity.ok(ApiResponse.success("Reports retrieved", reports));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * GET /api/reports/{id}
     * Get a specific report. Users can only access their own reports.
     */
    @GetMapping("/api/reports/{id}")
    public ResponseEntity<ApiResponse<ReportResponse>> getReportById(
            @PathVariable Long id) {
        try {
            String email = getCurrentUserEmail();
            ReportResponse response = reportService.getReportById(id, email, false);
            return ResponseEntity.ok(ApiResponse.success("Report retrieved", response));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // ============================================================
    // ADMIN endpoints (requires ADMIN role via SecurityConfig)
    // ============================================================

    /**
     * GET /api/admin/reports?status=PENDING
     * List all reports. Optional status filter.
     */
    @GetMapping("/api/admin/reports")
    public ResponseEntity<ApiResponse<List<ReportResponse>>> getAllReports(
            @RequestParam(required = false) String status) {
        try {
            List<ReportResponse> reports = reportService.getAllReports(status);
            return ResponseEntity.ok(ApiResponse.success("Reports retrieved", reports));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * GET /api/admin/reports/{id}
     * Admin view of a specific report (full details, any report).
     */
    @GetMapping("/api/admin/reports/{id}")
    public ResponseEntity<ApiResponse<ReportResponse>> adminGetReportById(
            @PathVariable Long id) {
        try {
            String email = getCurrentUserEmail();
            ReportResponse response = reportService.getReportById(id, email, true);
            return ResponseEntity.ok(ApiResponse.success("Report retrieved", response));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * PUT /api/admin/reports/{id}
     * Update status, admin note, and/or action taken.
     */
    @PutMapping("/api/admin/reports/{id}")
    public ResponseEntity<ApiResponse<ReportResponse>> updateReport(
            @PathVariable Long id,
            @RequestBody ReportUpdateRequest request) {
        try {
            ReportResponse response = reportService.updateReport(id, request);
            return ResponseEntity.ok(ApiResponse.success("Report updated", response));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // ============================================================
    // Helper
    // ============================================================

    private String getCurrentUserEmail() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()
                || "anonymousUser".equals(auth.getPrincipal())) {
            throw new RuntimeException("Unauthorized");
        }
        return auth.getName();
    }
}
