package com.sevalink.sevalinkbackend.dto;

import com.sevalink.sevalinkbackend.model.UserRole;
import lombok.Data;
import java.time.LocalDate;
@Data
public class UserDTO {
    private Long id;
    private String fullName;
    private String email;
    private String phoneNumber;
    private UserRole role;
    private LocalDate birthday;
    private Boolean isPhoneVerified;
    private Boolean isEmailVerified;
    private Boolean isActive;
}
