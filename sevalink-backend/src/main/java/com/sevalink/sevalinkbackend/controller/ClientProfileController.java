package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.dto.ApiResponse;
import com.sevalink.sevalinkbackend.dto.ClientProfileDto;
import com.sevalink.sevalinkbackend.dto.UpdateClientProfileRequest;
import com.sevalink.sevalinkbackend.service.ClientProfileService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/client/profile")
@CrossOrigin(origins = "*")
public class ClientProfileController {

    @Autowired
    private ClientProfileService clientProfileService;

    private String getCurrentUserEmail() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()
                || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new RuntimeException("Unauthorized");
        }
        return authentication.getName();
    }

    @GetMapping
    public ResponseEntity<ApiResponse<ClientProfileDto>> getProfile() {
        try {
            String email = getCurrentUserEmail();
            ClientProfileDto profile = clientProfileService.getClientProfile(email);
            return ResponseEntity.ok(ApiResponse.success("Profile fetched successfully", profile));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PutMapping
    public ResponseEntity<ApiResponse<ClientProfileDto>> updateProfile(
            @RequestBody UpdateClientProfileRequest request) {
        try {
            String email = getCurrentUserEmail();
            ClientProfileDto profile = clientProfileService.updateClientProfile(email, request);
            return ResponseEntity.ok(ApiResponse.success("Profile updated successfully", profile));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PostMapping("/image")
    public ResponseEntity<ApiResponse<ClientProfileDto>> uploadImage(
            @RequestParam("file") MultipartFile file) {
        try {
            String email = getCurrentUserEmail();
            ClientProfileDto profile = clientProfileService.uploadProfileImage(email, file);
            return ResponseEntity.ok(ApiResponse.success("Profile image uploaded successfully", profile));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}
