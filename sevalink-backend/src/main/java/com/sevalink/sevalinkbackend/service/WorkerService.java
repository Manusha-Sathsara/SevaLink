package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.repository.WorkerRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

@Service
public class WorkerService {

    @Autowired
    private WorkerRepository workerRepository;

    // Get all workers
    public List<Worker> getAllWorkers() {
        return workerRepository.findAll();
    }

    // Get worker by ID
    public Optional<Worker> getWorkerById(Long id) {
        return workerRepository.findById(id);
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
}