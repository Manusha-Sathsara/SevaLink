package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.ClientDashboardResponse;
import com.sevalink.sevalinkbackend.dto.WorkerProfileDto;
import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.repository.WorkerRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.sevalink.sevalinkbackend.model.WorkerStatus;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ClientDashboardService {

    @Autowired
    private WorkerRepository workerRepository;

    public ClientDashboardResponse getDashboardData() {
        List<Worker> topWorkers = workerRepository.findTop10ByIsAvailableTrueAndStatusOrderByRatingDesc(WorkerStatus.VERIFIED);
        if (topWorkers.isEmpty()) {
            topWorkers = workerRepository.findAll();
            if (topWorkers.size() > 10) {
                topWorkers = topWorkers.subList(0, 10);
            }
        }

        List<WorkerProfileDto> workerDtos = topWorkers.stream().map(worker -> {
            String name = (worker.getUser() != null && worker.getUser().getFullName() != null) 
                    ? worker.getUser().getFullName() : "Unknown Worker";
            String profession = (worker.getCategory() != null && worker.getCategory().getName() != null) 
                    ? worker.getCategory().getName() : "General";
            String imageUrl = (worker.getUser() != null) ? worker.getUser().getProfileImageUrl() : null;

            return WorkerProfileDto.builder()
                    .id(worker.getId())
                    .name(name)
                    .profession(profession)
                    .hourlyRate(worker.getHourlyRate() != null ? worker.getHourlyRate() : 1000.0)
                    .rating(worker.getRating() != null && worker.getRating() > 0 ? worker.getRating() : 5.0)
                    .reviewCount(worker.getTotalReviews() != null && worker.getTotalReviews() > 0 ? worker.getTotalReviews() : worker.getTotalJobs())
                    .isVerified(WorkerStatus.VERIFIED.equals(worker.getStatus()))
                    .imageUrl(imageUrl)
                    .build();
        }).collect(Collectors.toList());

        return ClientDashboardResponse.builder()
                .topWorkers(workerDtos)
                .build();
    }
}
