package com.sevalink.sevalinkbackend.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ClientJobStatsDto {
    private long total;
    private long open;
    private long active;
    private long done;
}
