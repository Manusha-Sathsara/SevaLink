package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.ClientProfileDto;
import com.sevalink.sevalinkbackend.dto.UpdateClientProfileRequest;
import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@Service
public class ClientProfileService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FileStorageService fileStorageService;

    public ClientProfileDto getClientProfile(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return ClientProfileDto.builder()
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phoneNumber(user.getPhoneNumber())
                .location(user.getLocation())
                .profileImageUrl(user.getProfileImageUrl())
                .createdAt(user.getCreatedAt())
                .build();
    }

    public ClientProfileDto updateClientProfile(String email, UpdateClientProfileRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setFullName(request.getFullName());
        user.setPhoneNumber(request.getPhoneNumber());
        user.setLocation(request.getLocation());

        userRepository.save(user);

        return getClientProfile(email);
    }

    public ClientProfileDto uploadProfileImage(String email, MultipartFile file) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        String fileName = fileStorageService.storeFile(file);
        
        // Build the public URL for the image
        String fileDownloadUri = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path("/api/public/uploads/")
                .path(fileName)
                .toUriString();

        user.setProfileImageUrl(fileDownloadUri);
        userRepository.save(user);

        return getClientProfile(email);
    }
}
