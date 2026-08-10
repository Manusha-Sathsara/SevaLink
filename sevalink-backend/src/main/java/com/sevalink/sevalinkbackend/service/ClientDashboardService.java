package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.ClientDashboardResponse;
import com.sevalink.sevalinkbackend.dto.WorkerProfileDto;
import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.repository.WorkerRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ClientDashboardService {

    @Autowired
    private WorkerRepository workerRepository;

    public ClientDashboardResponse getDashboardData() {
        List<Worker> topWorkers = workerRepository.findTop10ByIsAvailableTrueOrderByRatingDesc();

        List<WorkerProfileDto> workerDtos = topWorkers.stream().map(worker -> {
            String name = (worker.getUser() != null && worker.getUser().getFullName() != null) 
                    ? worker.getUser().getFullName() : "Unknown";
            String profession = (worker.getCategory() != null) 
                    ? worker.getCategory().getName() : "General";
            String imageUrl = null; // User model does not have profilePictureUrl

            return WorkerProfileDto.builder()
                    .id(worker.getId())
                    .name(name)
                    .profession(profession)
                    .hourlyRate(worker.getHourlyRate())
                    .rating(worker.getRating())
                    .reviewCount(worker.getTotalJobs()) // using totalJobs as proxy for reviewCount for now
                    .isVerified(worker.getUser() != null && (worker.getUser().getIsPhoneVerified() || worker.getUser().getIsEmailVerified()))
                    .imageUrl(imageUrl)
                    .build();
        }).collect(Collectors.toList());

        return ClientDashboardResponse.builder()
                .topWorkers(workerDtos)
                .build();
    }
}
