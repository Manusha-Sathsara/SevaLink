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

        // Notify nearby workers (within 15km radius)
        if (saved.getLatitude() != null && saved.getLongitude() != null) {
            List<Worker> nearbyWorkers = workerRepository.findNearbyWorkers(saved.getLatitude(), saved.getLongitude(), 15.0);
            for (Worker worker : nearbyWorkers) {
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
        }
        JobTimeline timeline = new JobTimeline();
        timeline.setJobPost(job);
        timeline.setStatus(status);
        timeline.setNote(note);
        JobTimeline saved = jobTimelineRepository.save(timeline);

        // Notify client about timeline state changes
        try {
            Quotation acceptedQuote = quotationRepository.findByJobPostIdAndStatus(job.getId(), "ACCEPTED").orElse(null);
            String workerName = (acceptedQuote != null && acceptedQuote.getWorker() != null && acceptedQuote.getWorker().getUser() != null)
                    ? acceptedQuote.getWorker().getUser().getFullName()
                    : "Worker";

            if ("WORKER_EN_ROUTE".equals(status)) {
                createNotification(job.getClient(), job, "Worker On The Way", 
                    "Worker " + workerName + " is on the way to your location.");
            } else if ("WORKER_ARRIVED".equals(status)) {
                createNotification(job.getClient(), job, "Worker Arrived", 
                    "Worker " + workerName + " has arrived at your location.");
            } else if ("JOB_STARTED".equals(status)) {
                createNotification(job.getClient(), job, "Job Started", 
                    "Work has started on '" + job.getTitle() + "'.");
            } else if ("JOB_DONE".equals(status)) {
                createNotification(job.getClient(), job, "Job Completed by Worker", 
                    "Worker " + workerName + " marked the job '" + job.getTitle() + "' as completed. Please confirm payment.");
            }
        } catch (Exception e) {
            System.err.println("Failed to create timeline notifications: " + e.getMessage());
        }

        return saved;
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

            // Notify worker that client confirmed payment
            Quotation acceptedQuote = quotationRepository.findByJobPostIdAndStatus(jobId, "ACCEPTED").orElse(null);
            if (acceptedQuote != null && acceptedQuote.getWorker() != null && acceptedQuote.getWorker().getUser() != null) {
                createNotification(acceptedQuote.getWorker().getUser(), job, "Payment Confirmed by Client",
                        "The client has confirmed payment for the job '" + job.getTitle() + "'.");
            }
        } else if (UserRole.WORKER.equals(user.getRole())) {
            Worker worker = workerRepository.findByUserId(user.getId())
                    .orElseThrow(() -> new RuntimeException("Worker profile not found"));
            Quotation acceptedQuote = quotationRepository.findByJobPostIdAndStatus(jobId, "ACCEPTED")
                    .orElseThrow(() -> new RuntimeException("No accepted quote found"));
            if (!acceptedQuote.getWorker().getId().equals(worker.getId())) {
                throw new RuntimeException("Unauthorized worker for this job");
            }
            job.setWorkerPaymentConfirmed(true);

            // Notify client that worker confirmed payment
            createNotification(job.getClient(), job, "Payment Confirmed by Worker",
                    "The worker " + user.getFullName() + " has confirmed receipt of payment for the job '" + job.getTitle() + "'.");
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

            // Notify both parties that the job is fully completed
            try {
                if (acceptedQuote != null && acceptedQuote.getWorker() != null && acceptedQuote.getWorker().getUser() != null) {
                    createNotification(acceptedQuote.getWorker().getUser(), job, "Job Fully Completed",
                            "Payment confirmed by both parties. Job '" + job.getTitle() + "' is fully completed!");
                }
                createNotification(job.getClient(), job, "Job Fully Completed",
                        "Payment confirmed by both parties. Job '" + job.getTitle() + "' is fully completed!");
            } catch (Exception e) {
                System.err.println("Failed to send completion notifications: " + e.getMessage());
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

        // Send notification to the other party
        try {
            if (UserRole.CLIENT.equals(user.getRole())) {
                Quotation acceptedQuote = quotationRepository.findByJobPostIdAndStatus(jobId, "ACCEPTED").orElse(null);
                if (acceptedQuote != null && acceptedQuote.getWorker() != null && acceptedQuote.getWorker().getUser() != null) {
                    createNotification(acceptedQuote.getWorker().getUser(), job, "Complaint Filed by Client",
                            "The client filed a complaint for the job '" + job.getTitle() + "': " + description);
                }
            } else if (UserRole.WORKER.equals(user.getRole())) {
                createNotification(job.getClient(), job, "Complaint Filed by Worker",
                        "The worker filed a complaint for the job '" + job.getTitle() + "': " + description);
            }
        } catch (Exception e) {
            System.err.println("Failed to send complaint notification: " + e.getMessage());
        }

        return saved;
    }

    // Client job statistics
    public ClientJobStatsDto getClientJobStats(Long clientId) {
        return ClientJobStatsDto.builder()
                .total(jobPostRepository.countByClientId(clientId))
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
            jobs = jobPostRepository.findByClientIdOrderByCreatedAtDesc(clientId);
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

    private void createNotification(User user, JobPost jobPost, String title, String message) {
        try {
            Notification notification = new Notification();
            notification.setUser(user);
            notification.setJobPost(jobPost);
            notification.setTitle(title);
            notification.setMessage(message);
            notificationRepository.save(notification);
        } catch (Exception e) {
            System.err.println("Failed to create notification: " + e.getMessage());
        }
    }
}
