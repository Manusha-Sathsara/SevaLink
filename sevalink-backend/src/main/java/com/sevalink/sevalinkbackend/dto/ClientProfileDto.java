package com.sevalink.sevalinkbackend.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class ClientProfileDto {
    private String fullName;
    private String email;
    private String phoneNumber;
    private String location;
    private String profileImageUrl;
    private LocalDateTime createdAt;
}
