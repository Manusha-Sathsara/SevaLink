package com.sevalink.sevalinkbackend.dto;

import lombok.Data;

@Data
public class UpdateWorkerProfileRequest {
    private String fullName;
    private String phoneNumber;
    private String location;
    private String bio;
    private String skills;
    private Double hourlyRate;
    private Long categoryId;
    private Double latitude;
    private Double longitude;
}
