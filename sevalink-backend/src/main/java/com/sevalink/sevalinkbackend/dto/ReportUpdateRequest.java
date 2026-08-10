package com.sevalink.sevalinkbackend.dto;

import com.sevalink.sevalinkbackend.model.ReportStatus;
import lombok.Data;

@Data
public class ReportUpdateRequest {

    // Admin can update status, note, and/or action taken in a single call
    private ReportStatus status;

    private String adminNote;

    private String actionTaken;
}
