package com.sevalink.sevalinkbackend.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class ClientJobDto {
    private Long id;
    private String title;
    private String description;
    private String categoryName;
    private String locationName;
    private Double budgetMin;
    private Double budgetMax;
    private String urgency;
    private String status;
    private LocalDateTime createdAt;
    private long quoteCount;
}
