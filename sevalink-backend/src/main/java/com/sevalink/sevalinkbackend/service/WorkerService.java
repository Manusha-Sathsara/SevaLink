package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.AdminWorkerDto;
import com.sevalink.sevalinkbackend.dto.UpdateWorkerProfileRequest;
import com.sevalink.sevalinkbackend.model.Category;
import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.model.WorkerStatus;
import com.sevalink.sevalinkbackend.repository.CategoryRepository;
import com.sevalink.sevalinkbackend.repository.WorkerRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class WorkerService {

    @Autowired
    private WorkerRepository workerRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private com.sevalink.sevalinkbackend.repository.UserRepository userRepository;

    @Autowired
    private FileStorageService fileStorageService;


    // Get all workers
    public List<Worker> getAllWorkers() {
        // Automatically ensure all WORKER users have a Worker profile
        List<com.sevalink.sevalinkbackend.model.User> allUsers = userRepository.findAll();
        for (com.sevalink.sevalinkbackend.model.User u : allUsers) {
            if (com.sevalink.sevalinkbackend.model.UserRole.WORKER.equals(u.getRole())) {
                boolean exists = workerRepository.findByUserId(u.getId()).isPresent();
                if (!exists) {
                    Worker newWorker = new Worker();
                    newWorker.setUser(u);
                    newWorker.setIsAvailable(true);
                    newWorker.setRating(5.0);
                    newWorker.setTotalJobs(0);
                    newWorker.setSkills("Electrician,AC Repair,Wiring");
                    newWorker.setStatus(WorkerStatus.PENDING);
                    workerRepository.save(newWorker);
                }
            }
        }
        return workerRepository.findAll();
    }

    public List<AdminWorkerDto> getAllWorkerDtos() {
        return getAllWorkers().stream()
                .map(this::toAdminWorkerDto)
                .collect(Collectors.toList());
    }

    private AdminWorkerDto toAdminWorkerDto(Worker worker) {
        return AdminWorkerDto.builder()
                .id(worker.getId())
                .fullName(worker.getUser() != null ? worker.getUser().getFullName() : "Unknown")
                .email(worker.getUser() != null ? worker.getUser().getEmail() : null)
                .phoneNumber(worker.getUser() != null ? worker.getUser().getPhoneNumber() : null)
                .category(worker.getCategory() != null ? worker.getCategory().getName() : "Uncategorized")
                .skills(worker.getSkills())
                .status(worker.getStatus() != null ? worker.getStatus().name() : WorkerStatus.PENDING.name())
                .rating(worker.getRating())
                .totalJobs(worker.getTotalJobs())
                .hourlyRate(worker.getHourlyRate())
                .isAvailable(worker.getIsAvailable())
                .createdAt(worker.getUser() != null ? worker.getUser().getCreatedAt() : null)
                .build();
    }

    public AdminWorkerDto updateWorkerStatus(Long workerId, WorkerStatus status) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new RuntimeException("Worker not found"));
        worker.setStatus(status);
        return toAdminWorkerDto(workerRepository.save(worker));
    }

    // Get worker by ID
    public Optional<Worker> getWorkerById(Long id) {
        return workerRepository.findById(id);
    }

    // Get worker profile of the currently authenticated user (by email)
    public Worker getWorkerByEmail(String email) {
        com.sevalink.sevalinkbackend.model.User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Auto-create worker profile if it doesn't exist
        return workerRepository.findByUserId(user.getId()).orElseGet(() -> {
            Worker newWorker = new Worker();
            newWorker.setUser(user);
            newWorker.setIsAvailable(true);
            newWorker.setRating(5.0);
            newWorker.setTotalJobs(0);
            newWorker.setStatus(WorkerStatus.PENDING);
            workerRepository.save(newWorker);
            return newWorker;
        });
    }

    // Search workers by keyword (e.g. "plumber", "electrician")
    public List<Worker> searchWorkers(String keyword) {
        return workerRepository.searchWorkers(keyword);
    }

    // Get only available workers
    public List<Worker> getAvailableWorkers() {
        return workerRepository.findByIsAvailableTrue();
    }

    // Update worker availability
    public Worker updateAvailability(Long workerId, Boolean status) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new RuntimeException("Worker not found"));
        worker.setIsAvailable(status);
        return workerRepository.save(worker);
    }

    // Update worker profile
    @Transactional
    public Worker updateWorkerProfile(Long workerId, UpdateWorkerProfileRequest request) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new RuntimeException("Worker not found"));

        com.sevalink.sevalinkbackend.model.User user = worker.getUser();
        if (user != null) {
            user.setFullName(request.getFullName());
            user.setPhoneNumber(request.getPhoneNumber());
            user.setLocation(request.getLocation());
            userRepository.save(user);
        }

        worker.setBio(request.getBio());
        worker.setSkills(request.getSkills());
        worker.setHourlyRate(request.getHourlyRate());

        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new RuntimeException("Category not found"));
            worker.setCategory(category);
        }

        worker.setLatitude(request.getLatitude());
        worker.setLongitude(request.getLongitude());

        return workerRepository.save(worker);
    }

    // Upload profile image
    @Transactional
    public Worker uploadProfileImage(Long workerId, MultipartFile file) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new RuntimeException("Worker not found"));

        com.sevalink.sevalinkbackend.model.User user = worker.getUser();
        if (user == null) {
            throw new RuntimeException("User not associated with worker");
        }

        String fileName = fileStorageService.storeFile(file);

        // Build the public URL for the image
        String fileDownloadUri = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path("/api/public/uploads/")
                .path(fileName)
                .toUriString();

        user.setProfileImageUrl(fileDownloadUri);
        userRepository.save(user);

        return worker;
    }

    // Update worker's live coordinates
    @Transactional
    public Worker updateWorkerLocation(Long workerId, Double latitude, Double longitude) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new RuntimeException("Worker not found"));
        worker.setLatitude(latitude);
        worker.setLongitude(longitude);
        return workerRepository.save(worker);
    }
}