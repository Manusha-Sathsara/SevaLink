package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.*;
import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import com.sevalink.sevalinkbackend.security.JwtTokenProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;  // BCrypt

    @Autowired
    private JwtTokenProvider jwtTokenProvider;


    @Autowired
    private EmailService emailService;

    /**
     * REGISTER - Create new user account
     * Flow: Validate → Create User → Hash Password → Save → Generate Tokens
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {

        // STEP 1: Validate email doesn't exist
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already registered");
        }

        // STEP 2: Validate phone doesn't exist
        if (userRepository.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new RuntimeException("Phone number already registered");
        }

        // STEP 3: Create new User entity from RegisterRequest
        User user = new User();
        user.setFullName(request.getFullName());
        user.setEmail(request.getEmail());
        user.setPhoneNumber(request.getPhoneNumber());
        user.setBirthday(request.getBirthday());
        user.setRole(request.getRole());  // CLIENT or WORKER from role selection

        // STEP 4: Hash the password (NEVER store plain text!)
        String hashedPassword = passwordEncoder.encode(request.getPassword());
        user.setPasswordHash(hashedPassword);

        // STEP 5: Set default values
        user.setIsPhoneVerified(false);   // Will verify via SMS later
        user.setIsActive(true);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());

        // STEP 6: Save to database
        User savedUser = userRepository.save(user);

        // STEP 7: Generate JWT tokens
        String accessToken = jwtTokenProvider.generateAccessToken(
                savedUser.getEmail(),
                savedUser.getRole()
        );
        String refreshToken = jwtTokenProvider.generateRefreshToken(savedUser.getEmail());

        // STEP 8: Convert User entity to UserDTO (hides password hash)
        UserDTO userDTO = convertToDTO(savedUser);

        // STEP 9: Return AuthResponse with tokens + user info
        return new AuthResponse(accessToken, refreshToken, userDTO);
    }

    /**
     * LOGIN - Authenticate existing user
     * Flow: Authenticate → Load User → Generate Tokens → Return
     */
    public AuthResponse login(LoginRequest request) {

        // STEP 1: Find user by email OR phone
        User user = userRepository.findByEmailOrPhoneNumber(request.getIdentifier())
                .orElseThrow(() -> new RuntimeException("Invalid credentials"));

        // STEP 2: Verify password using BCrypt
        // passwordEncoder.matches(plainText, hashedFromDatabase)
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Invalid credentials");
        }

        // STEP 3: Check if account is active
        if (!user.getIsActive()) {
            throw new RuntimeException("Account deactivated. Contact support.");
        }

        // STEP 4: Update last login time
        user.setLastLogin(LocalDateTime.now());
        userRepository.save(user);

        // STEP 5: Generate JWT tokens
        String accessToken = jwtTokenProvider.generateAccessToken(
                user.getEmail(),
                user.getRole()
        );
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getEmail());

        // STEP 6: Convert to DTO and return
        UserDTO userDTO = convertToDTO(user);
        return new AuthResponse(accessToken, refreshToken, userDTO);
    }

    /**
     * FORGOT PASSWORD - Send reset link to email
     * Flow: Find user †’ Generate random token †’ Save token †’ Send email
     */
    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found with this email"));

        // Check 1 minute wait time
        if (user.getResetPasswordLastSentAt() != null &&
            user.getResetPasswordLastSentAt().plusMinutes(1).isAfter(LocalDateTime.now())) {
            throw new RuntimeException("Please wait 1 minute before requesting another PIN");
        }

        // Generate 6-digit PIN
        String resetToken = String.format("%06d", new java.util.Random().nextInt(1000000));

        // Save token with expiry (5 minutes from now)
        user.setResetPasswordToken(resetToken);
        user.setResetPasswordTokenExpiry(LocalDateTime.now().plusMinutes(5));
        user.setResetPasswordLastSentAt(LocalDateTime.now());
        userRepository.save(user);

        // Send email with reset link
        emailService.sendPasswordResetEmail(user.getEmail(), resetToken);
    }

    /**
     * RESET PASSWORD - Actually change the password
     * Flow: Validate token → Update password → Clear reset token
     */
    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        // Find user by reset token
        User user = userRepository.findByResetPasswordToken(request.getToken())
                .orElseThrow(() -> new RuntimeException("Invalid or expired reset token"));

        // Check if token expired
        if (user.getResetPasswordTokenExpiry().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("Reset token has expired. Request a new one.");
        }

        // Update password (hash it first!)
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));

        // Clear reset token (can't be used again)
        user.setResetPasswordToken(null);
        user.setResetPasswordTokenExpiry(null);

        userRepository.save(user);
    }

    /**
     * REFRESH TOKEN - Get new access token using refresh token
     * Flow: Validate refresh token → Generate new access token
     */
    public AuthResponse refreshToken(String refreshToken) {
        // Validate refresh token
        if (!jwtTokenProvider.validateToken(refreshToken)) {
            throw new RuntimeException("Invalid refresh token");
        }

        // Extract email from refresh token
        String email = jwtTokenProvider.getEmailFromToken(refreshToken);

        // Find user
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Generate NEW access token
        String newAccessToken = jwtTokenProvider.generateAccessToken(
                user.getEmail(),
                user.getRole()
        );

        // Generate NEW refresh token (rotation)
        String newRefreshToken = jwtTokenProvider.generateRefreshToken(user.getEmail());

        UserDTO userDTO = convertToDTO(user);
        return new AuthResponse(newAccessToken, newRefreshToken, userDTO);
    }

    /**
     * LOGOUT - Invalidate tokens
     * For now, we just tell client to delete tokens
     * In production: Add token to blacklist in Redis
     */
    public void logout(String accessToken) {
        if (!jwtTokenProvider.validateToken(accessToken)) {
            throw new RuntimeException("Invalid access token");
        }
        // TODO: Add token to blacklist
        // This prevents the token from being used even if not expired
        SecurityContextHolder.clearContext();
    }

    /**
     * GET CURRENT USER - Get user info from email (from JWT)
     */
    public UserDTO getCurrentUser(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return convertToDTO(user);
    }

    /**
     * HELPER METHOD: Convert User entity to UserDTO
     * This is where we hide sensitive data (password hash)
     */
    private UserDTO convertToDTO(User user) {
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setFullName(user.getFullName());
        dto.setEmail(user.getEmail());
        dto.setPhoneNumber(user.getPhoneNumber());
        dto.setRole(user.getRole());
        dto.setBirthday(user.getBirthday());
        dto.setIsPhoneVerified(user.getIsPhoneVerified());
        dto.setIsActive(user.getIsActive());
        // Notice: passwordHash is NOT copied!
        return dto;
    }
}