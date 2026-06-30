package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.model.JobPost;
import com.sevalink.sevalinkbackend.model.JobTimeline;
import com.sevalink.sevalinkbackend.model.Notification;
import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.model.Quotation;
import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.model.UserRole;
import com.sevalink.sevalinkbackend.model.Complaint;
import com.sevalink.sevalinkbackend.repository.JobPostRepository;
import com.sevalink.sevalinkbackend.repository.JobTimelineRepository;
import com.sevalink.sevalinkbackend.repository.QuotationRepository;
import com.sevalink.sevalinkbackend.repository.WorkerRepository;
import com.sevalink.sevalinkbackend.repository.NotificationRepository;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import com.sevalink.sevalinkbackend.repository.ComplaintRepository;
import com.sevalink.sevalinkbackend.dto.ClientJobStatsDto;
import com.sevalink.sevalinkbackend.dto.ClientJobDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class JobPostService {

    @Autowired
    private JobPostRepository jobPostRepository;

    @Autowired
    private JobTimelineRepository jobTimelineRepository;

    @Autowired
    private QuotationRepository quotationRepository;

    @Autowired
    private WorkerRepository workerRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ComplaintRepository complaintRepository;

    // Client posts a new job
    public JobPost createJob(JobPost jobPost) {
        JobPost saved = jobPostRepository.save(jobPost);

        // Auto create first timeline entry
        JobTimeline timeline = new JobTimeline();
        timeline.setJobPost(saved);
        timeline.setStatus("JOB_POSTED");
        timeline.setNote("Job posted by client");
        jobTimelineRepository.save(timeline);

        // Notify relevant nearby workers (within 15 km, matching job category)
        if (saved.getLatitude() != null && saved.getLongitude() != null) {
            List<Worker> targetWorkers;

            if (saved.getCategory() != null) {
                // Category-aware: only notify workers in the same trade within 15 km
                targetWorkers = workerRepository.findNearbyWorkersByCategory(
                        saved.getLatitude(), saved.getLongitude(), 15.0,
                        saved.getCategory().getId());
            } else {
                // No category on job — fall back to proximity-only
                targetWorkers = workerRepository.findNearbyWorkers(
                        saved.getLatitude(), saved.getLongitude(), 15.0);
            }

            for (Worker worker : targetWorkers) {
                if (worker.getUser() != null) {
                    Notification notification = new Notification();
                    notification.setUser(worker.getUser());
                    notification.setJobPost(saved);
                    notification.setTitle("New Job Nearby");
                    notification.setMessage("A new job '" + saved.getTitle() + "' was posted near you.");
                    notificationRepository.save(notification);
                }
            }
        }

        return saved;
    }

    // Get all open jobs (worker feed — auto-filtered by worker's trade category)
    public List<JobPost> getAllOpenJobs() {
        // If the caller is a logged-in worker, restrict results to their category
        User caller = getCurrentAuthenticatedUser();
        if (caller != null && UserRole.WORKER.equals(caller.getRole())) {
            Optional<Worker> workerOpt = workerRepository.findByUserId(caller.getId());
            if (workerOpt.isPresent() && workerOpt.get().getCategory() != null) {
                Long categoryId = workerOpt.get().getCategory().getId();
                return jobPostRepository.findByStatusAndCategoryIdOrderByCreatedAtDesc("OPEN", categoryId);
            }
        }
        return jobPostRepository.findByStatusOrderByCreatedAtDesc("OPEN");
    }

    // Admin view: get all jobs regardless of status
    public List<JobPost> getAllJobsAdmin() {
        return jobPostRepository.findAll();
    }

    // Update a job record for admin management
    @Transactional
    public JobPost updateJob(Long jobId, JobPost payload) {
        JobPost job = jobPostRepository.findById(jobId)
                .orElseThrow(() -> new RuntimeException("Job not found"));
        if (payload.getTitle() != null) {
            job.setTitle(payload.getTitle());
        }
        if (payload.getDescription() != null) {
            job.setDescription(payload.getDescription());
        }
        if (payload.getLocationName() != null) {
            job.setLocationName(payload.getLocationName());
        }
        if (payload.getBudgetMin() != null) {
            job.setBudgetMin(payload.getBudgetMin());
        }
        if (payload.getBudgetMax() != null) {
            job.setBudgetMax(payload.getBudgetMax());
        }
        if (payload.getUrgency() != null) {
            job.setUrgency(payload.getUrgency());
        }
        if (payload.getStatus() != null) {
            job.setStatus(payload.getStatus());
        }
        return jobPostRepository.save(job);
    }

    // Get all open jobs excluding those the worker already quoted
    public List<JobPost> getAllOpenJobsForWorker(Long workerId) {
        return jobPostRepository.findOpenJobsExcludingWorkerQuotes(workerId);
    }

    // Get open jobs for a specific category — worker category-targeted feed
    public List<JobPost> getOpenJobsByCategory(Long categoryId) {
        return jobPostRepository.findByStatusAndCategoryIdOrderByCreatedAtDesc("OPEN", categoryId);
    }

    // Get open jobs for a category, excluding those the worker already quoted
    public List<JobPost> getOpenJobsByCategoryForWorker(Long categoryId, Long workerId) {
        return jobPostRepository.findOpenJobsByCategoryExcludingWorkerQuotes(categoryId, workerId);
    }

    // Worker sees nearby jobs (auto-filtered by worker's trade category)
    public List<JobPost> getNearbyJobs(Double lat, Double lng, Double radius) {
        double r = (radius != null) ? radius : 10.0;
        // If the caller is a logged-in worker, restrict results to their category
        User caller = getCurrentAuthenticatedUser();
        if (caller != null && UserRole.WORKER.equals(caller.getRole())) {
            Optional<Worker> workerOpt = workerRepository.findByUserId(caller.getId());
            if (workerOpt.isPresent() && workerOpt.get().getCategory() != null) {
                Long categoryId = workerOpt.get().getCategory().getId();
                return jobPostRepository.findNearbyJobsByCategory(lat, lng, r, categoryId);
            }
        }
        return jobPostRepository.findNearbyJobs(lat, lng, r);
    }

    // Worker sees nearby jobs, excluding those they already quoted
    public List<JobPost> getNearbyJobsForWorker(Double lat, Double lng, Double radius, Long workerId) {
        double r = (radius != null) ? radius : 10.0;
        return jobPostRepository.findNearbyJobsExcludingWorkerQuotes(lat, lng, r, workerId);
    }

    // Worker sees nearby jobs by category
    public List<JobPost> getNearbyJobsByCategory(Double lat, Double lng,
                                                 Double radius, Long categoryId) {
        double r = (radius != null) ? radius : 10.0;
        return jobPostRepository.findNearbyJobsByCategory(lat, lng, r, categoryId);
    }

    // Worker sees nearby jobs by category, excluding those they already quoted
    public List<JobPost> getNearbyJobsByCategoryForWorker(Double lat, Double lng,
                                                          Double radius, Long categoryId, Long workerId) {
        double r = (radius != null) ? radius : 10.0;
        return jobPostRepository.findNearbyJobsByCategoryExcludingWorkerQuotes(lat, lng, r, categoryId, workerId);
    }

    // Get job by ID
    public Optional<JobPost> getJobById(Long id) {
        return jobPostRepository.findById(id);
    }

    // Client sees their own jobs
    public List<JobPost> getClientJobs(Long clientId) {
        return jobPostRepository.findByClientIdAndStatusNotOrderByCreatedAtDesc(clientId, "DELETED");
    }

    // Delete a job
    public JobPost deleteJob(Long jobId, String reason, Long clientId) {
        JobPost job = jobPostRepository.findById(jobId)
                .orElseThrow(() -> new RuntimeException("Job not found"));
        if (job.getClient() == null || job.getClient().getId() != clientId.longValue()) {
            throw new RuntimeException("Unauthorized to delete this job");
        }
        if ("COMPLETED".equals(job.getStatus())) {
            throw new RuntimeException("Cannot delete a completed job");
        }
        
        // Notify any workers who have submitted quotes or are assigned
        List<com.sevalink.sevalinkbackend.model.Quotation> quotes = quotationRepository.findByJobPostIdOrderByProposedPriceAsc(jobId);
        for (com.sevalink.sevalinkbackend.model.Quotation quote : quotes) {
            if ("ACCEPTED".equals(quote.getStatus()) || "OPEN".equals(quote.getStatus())) {
                Worker worker = quote.getWorker();
                if (worker != null && worker.getUser() != null) {
                    Notification notification = new Notification();
                    notification.setUser(worker.getUser());
                    notification.setJobPost(job);
                    notification.setTitle("Job Cancelled");
                    notification.setMessage("The client has cancelled the job '" + job.getTitle() + "'. Reason: " + reason);
                    notificationRepository.save(notification);
                }
            }
        }

        job.setStatus("CANCELLED");
        job.setDeletionReason(reason);
        return jobPostRepository.save(job);
    }

    // Cancel a job (only allowed before worker has arrived)
    @Transactional
    public JobPost cancelJob(Long jobId) {
        JobPost job = jobPostRepository.findById(jobId)
                .orElseThrow(() -> new RuntimeException("Job not found"));

        List<JobTimeline> timeline = jobTimelineRepository.findByJobPostIdOrderByUpdatedAtAsc(jobId);
        boolean arrived = timeline.stream().anyMatch(t -> 
                "WORKER_ARRIVED".equals(t.getStatus()) || 
                "JOB_STARTED".equals(t.getStatus()) || 
                "JOB_DONE".equals(t.getStatus()) || 
                "PAYMENT_DONE".equals(t.getStatus()));

        if (arrived) {
            throw new RuntimeException("Cannot cancel job after worker has arrived. You must file a complaint instead.");
        }

        job.setStatus("CANCELLED");
        JobPost saved = jobPostRepository.save(job);

        // Add timeline entry
        JobTimeline cancelTimeline = new JobTimeline();
        cancelTimeline.setJobPost(saved);
        cancelTimeline.setStatus("CANCELLED");
        cancelTimeline.setNote("Job cancelled by user");
        jobTimelineRepository.save(cancelTimeline);

        return saved;
    }

    // Get job timeline
    public List<JobTimeline> getJobTimeline(Long jobId) {
        return jobTimelineRepository.findByJobPostIdOrderByUpdatedAtAsc(jobId);
    }

    // Update job timeline
    public JobTimeline updateTimeline(Long jobId, String status, String note) {
        JobPost job = jobPostRepository.findById(jobId)
                .orElseThrow(() -> new RuntimeException("Job not found"));
        if ("COMPLETED".equals(status)) {
            job.setStatus("COMPLETED");
            jobPostRepository.save(job);

            // Increment the worker's total job count and experience
            quotationRepository.findByJobPostIdAndStatus(jobId, "ACCEPTED")
                    .ifPresent(acceptedQuote -> {
                        Worker worker = acceptedQuote.getWorker();
                        int current = worker.getTotalJobs() != null ? worker.getTotalJobs() : 0;
                        worker.setTotalJobs(current + 1);
                        workerRepository.save(worker);
                        
                        // Notify Client
                        Notification notification = new Notification();
                        notification.setUser(job.getClient());
                        notification.setJobPost(job);
                        notification.setTitle("Job Completed");
                        notification.setMessage("Your job '" + job.getTitle() + "' has been marked as completed by " + worker.getUser().getFullName() + ". Please review and rate the worker.");
                        notificationRepository.save(notification);
                    });
        }
        JobTimeline timeline = new JobTimeline();
        timeline.setJobPost(job);
        timeline.setStatus(status);
        timeline.setNote(note);
        return jobTimelineRepository.save(timeline);
    }

    // Client deletes/removes a job post
    @Transactional
    public void deleteJob(Long jobId) {
        JobPost job = jobPostRepository.findById(jobId)
                .orElseThrow(() -> new RuntimeException("Job not found"));

        complaintRepository.deleteByJobPostId(jobId);
        jobTimelineRepository.deleteByJobPostId(jobId);
        notificationRepository.deleteByJobPostId(jobId);
        quotationRepository.deleteByJobPostId(jobId);

        jobPostRepository.delete(job);
    }

    // Confirm payment from Client or Worker
    @Transactional
    public JobPost confirmPayment(Long jobId, String email) {
        JobPost job = jobPostRepository.findById(jobId)
                .orElseThrow(() -> new RuntimeException("Job not found"));
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (UserRole.CLIENT.equals(user.getRole())) {
            if (job.getClient().getId() != user.getId()) {
                throw new RuntimeException("Unauthorized client for this job");
            }
            job.setClientPaymentConfirmed(true);
        } else if (UserRole.WORKER.equals(user.getRole())) {
            Worker worker = workerRepository.findByUserId(user.getId())
                    .orElseThrow(() -> new RuntimeException("Worker profile not found"));
            Quotation acceptedQuote = quotationRepository.findByJobPostIdAndStatus(jobId, "ACCEPTED")
                    .orElseThrow(() -> new RuntimeException("No accepted quote found"));
            if (!acceptedQuote.getWorker().getId().equals(worker.getId())) {
                throw new RuntimeException("Unauthorized worker for this job");
            }
            job.setWorkerPaymentConfirmed(true);
        } else {
            throw new RuntimeException("Invalid role for payment confirmation");
        }

        // If both confirmed, transition to COMPLETED
        if (Boolean.TRUE.equals(job.getClientPaymentConfirmed()) && Boolean.TRUE.equals(job.getWorkerPaymentConfirmed())) {
            job.setStatus("COMPLETED");
            
            // Add timeline entry
            JobTimeline timeline = new JobTimeline();
            timeline.setJobPost(job);
            timeline.setStatus("PAYMENT_DONE");
            timeline.setNote("Payment completed & confirmed by both parties");
            jobTimelineRepository.save(timeline);

            // Increment worker's completed jobs count
            Quotation acceptedQuote = quotationRepository.findByJobPostIdAndStatus(jobId, "ACCEPTED").orElse(null);
            if (acceptedQuote != null && acceptedQuote.getWorker() != null) {
                Worker worker = acceptedQuote.getWorker();
                worker.setTotalJobs((worker.getTotalJobs() != null ? worker.getTotalJobs() : 0) + 1);
                workerRepository.save(worker);
            }
        }

        return jobPostRepository.save(job);
    }

    // Get assigned worker for client tracking
    public Worker getAssignedWorker(Long jobId) {
        Quotation acceptedQuote = quotationRepository.findByJobPostIdAndStatus(jobId, "ACCEPTED")
                .orElseThrow(() -> new RuntimeException("No accepted quotation found for this job"));
        return acceptedQuote.getWorker();
    }

    // File a complaint (after worker arrival)
    @Transactional
    public Complaint fileComplaint(Long jobId, String email, String description) {
        JobPost job = jobPostRepository.findById(jobId)
                .orElseThrow(() -> new RuntimeException("Job not found"));
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Save Complaint record
        Complaint complaint = new Complaint();
        complaint.setJobPost(job);
        complaint.setFiledBy(user);
        complaint.setDescription(description);
        Complaint saved = complaintRepository.save(complaint);

        // Add timeline entry
        JobTimeline timeline = new JobTimeline();
        timeline.setJobPost(job);
        timeline.setStatus("COMPLAINT_FILED");
        timeline.setNote("Complaint filed by " + user.getRole().name() + ": " + description);
        jobTimelineRepository.save(timeline);

        return saved;
    }

    // Client job statistics
    public ClientJobStatsDto getClientJobStats(Long clientId) {
        return ClientJobStatsDto.builder()
                .total(jobPostRepository.countByClientIdAndStatusNot(clientId, "DELETED"))
                .open(jobPostRepository.countByClientIdAndStatus(clientId, "OPEN"))
                .active(jobPostRepository.countByClientIdAndStatus(clientId, "ASSIGNED"))
                .done(jobPostRepository.countByClientIdAndStatus(clientId, "COMPLETED"))
                .build();
    }

    // Client jobs with quote counts
    public List<ClientJobDto> getClientJobsWithQuotes(Long clientId, String statusFilter) {
        List<JobPost> jobs;
        if (statusFilter != null && !statusFilter.equalsIgnoreCase("ALL")) {
            jobs = jobPostRepository.findByClientIdAndStatusInOrderByCreatedAtDesc(
                    clientId, List.of(statusFilter.toUpperCase()));
        } else {
            jobs = jobPostRepository.findByClientIdAndStatusNotOrderByCreatedAtDesc(clientId, "DELETED");
        }

        return jobs.stream().map(job -> {
            long quoteCount = quotationRepository.findByJobPostIdOrderByProposedPriceAsc(job.getId())
                    .stream()
                    .filter(q -> !"REJECTED".equals(q.getStatus()))
                    .count();
            return ClientJobDto.builder()
                    .id(job.getId())
                    .title(job.getTitle())
                    .description(job.getDescription())
                    .categoryName(job.getCategory() != null ? job.getCategory().getName() : "General")
                    .locationName(job.getLocationName())
                    .budgetMin(job.getBudgetMin())
                    .budgetMax(job.getBudgetMax())
                    .urgency(job.getUrgency())
                    .status(job.getStatus())
                    .createdAt(job.getCreatedAt())
                    .quoteCount(quoteCount)
                    .build();
        }).collect(Collectors.toList());
    }

    // ------------------------------------------------------------------------
    // SECURITY & DISTANCE CALCULATION METHODS FOR WORKERS
    // ------------------------------------------------------------------------

    public static String getApproximateLocation(String fullAddress) {
        if (fullAddress == null || fullAddress.trim().isEmpty()) {
            return "Unknown Location";
        }
        String[] parts = fullAddress.split(",");
        int startIndex = parts.length - 1;
        while (startIndex >= 0) {
            String part = parts[startIndex].trim();
            if (part.equalsIgnoreCase("Sri Lanka")) {
                startIndex--;
                continue;
            }
            if (part.toLowerCase().contains("colombo")) {
                java.util.regex.Pattern p = java.util.regex.Pattern.compile("colombo\\s*(?:00|0)?(\\d{1,2})00", java.util.regex.Pattern.CASE_INSENSITIVE);
                java.util.regex.Matcher m = p.matcher(part);
                if (m.find()) {
                    int district = Integer.parseInt(m.group(1));
                    return String.format("Colombo %02d", district);
                }
                java.util.regex.Pattern p2 = java.util.regex.Pattern.compile("colombo\\s*(\\d+)", java.util.regex.Pattern.CASE_INSENSITIVE);
                java.util.regex.Matcher m2 = p2.matcher(part);
                if (m2.find()) {
                    int district = Integer.parseInt(m2.group(1));
                    return String.format("Colombo %02d", district);
                }
                return "Colombo";
            }
            if (part.matches("\\d+") || part.matches(".*\\d{5}.*")) {
                part = part.replaceAll("\\d+", "").trim();
            }
            if (!part.isEmpty() && !part.matches(".*\\b(?:No|Street|Rd|Road|Lane|Avenue|Ave|Floor|Room|Apt|Apartment)\\b.*")) {
                return part;
            }
            startIndex--;
        }
        if (parts.length > 1) {
            String fallback = parts[parts.length - 2].trim();
            return fallback.replaceAll("\\d+", "").trim();
        }
        return fullAddress;
    }

    public static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
        double earthRadius = 6371; // km
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                   Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return earthRadius * c;
    }

    public JobPost getMaskedJobPostCopy(JobPost original, Double workerLat, Double workerLng) {
        JobPost copy = new JobPost();
        copy.setId(original.getId());
        copy.setClient(original.getClient());
        copy.setCategory(original.getCategory());
        copy.setTitle(original.getTitle());
        copy.setDescription(original.getDescription());
        copy.setBudgetMin(original.getBudgetMin());
        copy.setBudgetMax(original.getBudgetMax());
        copy.setUrgency(original.getUrgency());
        copy.setPhotos(original.getPhotos());
        copy.setStatus(original.getStatus());
        copy.setCreatedAt(original.getCreatedAt());
        
        // Mask location for workers browsing
        copy.setLocationName(getApproximateLocation(original.getLocationName()));
        copy.setLatitude(null);
        copy.setLongitude(null);
        
        // Compute distance if worker coordinates are available
        if (workerLat != null && workerLng != null && original.getLatitude() != null && original.getLongitude() != null) {
            double dist = calculateDistanceKm(workerLat, workerLng, original.getLatitude(), original.getLongitude());
            copy.setDistanceKm(dist);
        }
        
        return copy;
    }

    public JobPost processJobPostForUser(JobPost job, Double requestLat, Double requestLng) {
        try {
            org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.isAuthenticated() && !"anonymousUser".equals(auth.getPrincipal())) {
                String email = auth.getName();
                Optional<User> userOpt = userRepository.findByEmail(email);
                if (userOpt.isPresent()) {
                    User user = userOpt.get();
                    if (UserRole.CLIENT.equals(user.getRole()) || UserRole.ADMIN.equals(user.getRole())) {
                        // Client or Admin: see exact location
                        return job;
                    }
                    
                    // Worker: check if assigned to this job
                    Optional<Worker> workerOpt = workerRepository.findByUserId(user.getId());
                    if (workerOpt.isPresent()) {
                        Worker worker = workerOpt.get();
                        Optional<Quotation> acceptedQuote = quotationRepository.findByJobPostIdAndStatus(job.getId(), "ACCEPTED");
                        if (acceptedQuote.isPresent() && acceptedQuote.get().getWorker().getId().equals(worker.getId())) {
                            // Assigned worker: see exact location
                            return job;
                        }
                        
                        // Otherwise, mask location and compute distance
                        Double workerLat = requestLat != null ? requestLat : worker.getLatitude();
                        Double workerLng = requestLng != null ? requestLng : worker.getLongitude();
                        return getMaskedJobPostCopy(job, workerLat, workerLng);
                    }
                }
            }
        } catch (Exception e) {
            // fallback
        }
        // Fallback to masked
        return getMaskedJobPostCopy(job, requestLat, requestLng);
    }

    private User getCurrentAuthenticatedUser() {
        try {
            org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.isAuthenticated() && !"anonymousUser".equals(auth.getPrincipal())) {
                String email = auth.getName();
                return userRepository.findByEmail(email).orElse(null);
            }
        } catch (Exception e) {
            // ignore
        }
        return null;
    }

    private List<JobPost> filterQuotedJobsForCurrentWorker(List<JobPost> jobs) {
        User user = getCurrentAuthenticatedUser();
        if (user != null && UserRole.WORKER.equals(user.getRole())) {
            Optional<Worker> workerOpt = workerRepository.findByUserId(user.getId());
            if (workerOpt.isPresent()) {
                Worker worker = workerOpt.get();
                List<Long> quotedJobIds = quotationRepository.findByWorkerIdOrderByCreatedAtDesc(worker.getId())
                        .stream()
                        .map(q -> q.getJobPost().getId())
                        .collect(Collectors.toList());
                return jobs.stream()
                        .filter(j -> !quotedJobIds.contains(j.getId()))
                        .collect(Collectors.toList());
            }
        }
        return jobs;
    }

    // Processed Feed Wrappers
    public List<JobPost> getAllOpenJobsProcessed(Double requestLat, Double requestLng) {
        List<JobPost> jobs = getAllOpenJobs();
        jobs = filterQuotedJobsForCurrentWorker(jobs);
        return jobs.stream()
                .map(job -> processJobPostForUser(job, requestLat, requestLng))
                .collect(Collectors.toList());
    }

    public List<JobPost> getNearbyJobsProcessed(Double lat, Double lng, Double radius) {
        List<JobPost> jobs = getNearbyJobs(lat, lng, radius);
        jobs = filterQuotedJobsForCurrentWorker(jobs);
        return jobs.stream()
                .map(job -> processJobPostForUser(job, lat, lng))
                .collect(Collectors.toList());
    }

    public List<JobPost> getNearbyJobsByCategoryProcessed(Double lat, Double lng, Double radius, Long categoryId) {
        List<JobPost> jobs = getNearbyJobsByCategory(lat, lng, radius, categoryId);
        jobs = filterQuotedJobsForCurrentWorker(jobs);
        return jobs.stream()
                .map(job -> processJobPostForUser(job, lat, lng))
                .collect(Collectors.toList());
    }

    public Optional<JobPost> getJobByIdProcessed(Long id) {
        return getJobById(id).map(job -> processJobPostForUser(job, null, null));
    }
}
