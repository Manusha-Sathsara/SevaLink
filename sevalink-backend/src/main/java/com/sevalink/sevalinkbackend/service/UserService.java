package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.Optional;
import java.util.List;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    // Register new user
    public User registerUser(User user) {
        if (userRepository.existsByEmail(user.getEmail())) {
            throw new RuntimeException("Email already registered");
        }
        return userRepository.save(user);
    }

    // Find user by email (for login)
    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    // Get user by ID
    public Optional<User> getUserById(Long id) {
        return userRepository.findById(id);
    }

    // Get all users
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    // Update existing user fields (partial)
    public User updateUser(Long id, User changes) {
        User user = userRepository.findById(id).orElseThrow(() -> new RuntimeException("User not found"));
        if (changes.getFullName() != null) user.setFullName(changes.getFullName());
        if (changes.getPhoneNumber() != null) user.setPhoneNumber(changes.getPhoneNumber());
        if (changes.getLocation() != null) user.setLocation(changes.getLocation());
        if (changes.getRole() != null) user.setRole(changes.getRole());
        if (changes.getIsActive() != null) user.setIsActive(changes.getIsActive());
        return userRepository.save(user);
    }

    // Soft-delete (block) user by setting isActive=false
    public void blockUser(Long id) {
        User user = userRepository.findById(id).orElseThrow(() -> new RuntimeException("User not found"));
        user.setIsActive(false);
        userRepository.save(user);
    }
}
