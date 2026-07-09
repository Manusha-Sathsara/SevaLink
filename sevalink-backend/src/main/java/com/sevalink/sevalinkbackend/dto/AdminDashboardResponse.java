package com.sevalink.sevalinkbackend.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AdminDashboardResponse {
    private long totalUsers;
    private long totalWorkers;
    private long totalJobs;
    private long onlineUsers;
}
