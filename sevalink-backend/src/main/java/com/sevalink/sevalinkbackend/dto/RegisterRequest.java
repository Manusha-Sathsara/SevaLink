package com.sevalink.sevalinkbackend.dto;

import com.sevalink.sevalinkbackend.model.UserRole;
import jakarta.validation.constraints.*;
import lombok.Data;
import java.time.LocalDate;

@Data
public class RegisterRequest {
    @NotBlank(message =  "Full name is required")
    @Size (min = 2, max = 100, message = "Name must be between 2 and 100 characters")
    private String fullName;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Phone number is required")
    @Pattern(regexp = "^[+]?[0-9]{10,15}$", message = "Invalid phone number format")
    private String phoneNumber;

    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password must be at least 6 characters")
    private String password;

    @NotNull(message = "Birthday is Required")
    @Past(message = "Birthday must be in the past")
    private LocalDate birthday;

    @NotNull(message = "Role is required")
    private UserRole role;
}
