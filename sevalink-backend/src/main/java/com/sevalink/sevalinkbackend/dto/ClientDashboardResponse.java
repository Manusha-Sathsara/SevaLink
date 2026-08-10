package com.sevalink.sevalinkbackend.dto;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class ClientDashboardResponse {
    private List<WorkerProfileDto> topWorkers;
}
