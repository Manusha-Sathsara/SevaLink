package com.sevalink.sevalinkbackend.dto;

import java.time.LocalDateTime;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AdminWorkerDto {
    private Long id;
    private String fullName;
    private String email;
    private String phoneNumber;
    private String category;
    private String skills;
    private String status;
    private Double rating;
    private Integer totalJobs;
    private Double hourlyRate;
    private Boolean isAvailable;
    private LocalDateTime createdAt;
}
