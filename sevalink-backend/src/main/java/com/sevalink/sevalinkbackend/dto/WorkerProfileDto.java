package com.sevalink.sevalinkbackend.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class WorkerProfileDto {
    private Long id;
    private String name;
    private String profession;
    private Double hourlyRate;
    private Double rating;
    private Integer reviewCount;
    private Boolean isVerified;
    private String imageUrl;
}
