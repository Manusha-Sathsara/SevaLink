package com.sevalink.sevalinkbackend.dto;

import lombok.Data;

@Data
public class UpdateClientProfileRequest {
    private String fullName;
    private String phoneNumber;
    private String location;
}
