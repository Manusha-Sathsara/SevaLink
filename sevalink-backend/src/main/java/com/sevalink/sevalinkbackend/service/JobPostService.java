package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.model.JobPost;
import com.sevalink.sevalinkbackend.model.JobTimeline;
import com.sevalink.sevalinkbackend.repository.JobPostRepository;
import com.sevalink.sevalinkbackend.repository.JobTimelineRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

@Service
public class JobPostService {

    @Autowired
    private JobPostRepository jobPostRepository;

    @Autowired
    private JobTimelineRepository jobTimelineRepository;

    // Client posts a new job
    public JobPost createJob(JobPost jobPost) {
        JobPost saved = jobPostRepository.save(jobPost);

        // Auto create first timeline entry
        JobTimeline timeline = new JobTimeline();
        timeline.setJobPost(saved);
        timeline.setStatus("JOB_POSTED");
        timeline.setNote("Job posted by client");
        jobTimelineRepository.save(timeline);

        return saved;
    }

    // Get all open jobs (worker feed)
    public List<JobPost> getAllOpenJobs() {
        return jobPostRepository.findByStatusOrderByCreatedAtDesc("OPEN");
    }

    // Worker sees nearby jobs
    public List<JobPost> getNearbyJobs(Double lat, Double lng, Double radius) {
        double r = (radius != null) ? radius : 10.0;
        return jobPostRepository.findNearbyJobs(lat, lng, r);
    }

    // Worker sees nearby jobs by category
    public List<JobPost> getNearbyJobsByCategory(Double lat, Double lng,
                                                 Double radius, Long categoryId) {
        double r = (radius != null) ? radius : 10.0;
        return jobPostRepository.findNearbyJobsByCategory(lat, lng, r, categoryId);
    }

    // Get job by ID
    public Optional<JobPost> getJobById(Long id) {
        return jobPostRepository.findById(id);
    }

    // Client sees their own jobs
    public List<JobPost> getClientJobs(Long clientId) {
        return jobPostRepository.findByClientIdOrderByCreatedAtDesc(clientId);
    }

    // Cancel a job
    public JobPost cancelJob(Long jobId) {
        JobPost job = jobPostRepository.findById(jobId)
                .orElseThrow(() -> new RuntimeException("Job not found"));
        job.setStatus("CANCELLED");
        return jobPostRepository.save(job);
    }

    // Get job timeline
    public List<JobTimeline> getJobTimeline(Long jobId) {
        return jobTimelineRepository.findByJobPostIdOrderByUpdatedAtAsc(jobId);
    }

    // Update job timeline
    public JobTimeline updateTimeline(Long jobId, String status, String note) {
        JobPost job = jobPostRepository.findById(jobId)
                .orElseThrow(() -> new RuntimeException("Job not found"));
        JobTimeline timeline = new JobTimeline();
        timeline.setJobPost(job);
        timeline.setStatus(status);
        timeline.setNote(note);
        return jobTimelineRepository.save(timeline);
    }
}
