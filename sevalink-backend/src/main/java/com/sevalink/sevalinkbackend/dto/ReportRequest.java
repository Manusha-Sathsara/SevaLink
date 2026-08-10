package com.sevalink.sevalinkbackend.dto;

import com.sevalink.sevalinkbackend.model.ReportType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ReportRequest {

    @NotNull(message = "Reported user ID is required")
    private Long reportedUserId;

    // Optional — if the report is linked to a specific job
    private Long jobId;

    @NotNull(message = "Report type is required")
    private ReportType reportType;

    @NotBlank(message = "Description is required")
    private String description;

    // Optional evidence (URL, description of screenshot, etc.)
    private String evidence;
}
