package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.AdminDashboardResponse;
import com.sevalink.sevalinkbackend.model.UserRole;
import com.sevalink.sevalinkbackend.repository.JobPostRepository;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class AdminDashboardService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JobPostRepository jobPostRepository;

    public AdminDashboardResponse getDashboardStats() {
        long totalUsers = userRepository.count();
        long totalWorkers = userRepository.countByRole(UserRole.WORKER);
        long totalJobs = jobPostRepository.count();
        long onlineUsers = userRepository.countByIsActiveTrueAndLastLoginAfter(LocalDateTime.now().minusMinutes(10));

        return AdminDashboardResponse.builder()
                .totalUsers(totalUsers)
                .totalWorkers(totalWorkers)
                .totalJobs(totalJobs)
                .onlineUsers(onlineUsers)
                .build();
    }
}
