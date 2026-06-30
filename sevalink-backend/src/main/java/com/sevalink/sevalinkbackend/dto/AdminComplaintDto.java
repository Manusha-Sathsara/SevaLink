package com.sevalink.sevalinkbackend.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class AdminComplaintDto {
    private Long id;
    private Long jobId;
    private String jobTitle;
    private String filedByName;
    private String filedByEmail;
    private String description;
    private String category;
    private String priority;
    private String status;
    private LocalDateTime createdAt;
}
