package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.model.JobPost;
import com.sevalink.sevalinkbackend.model.JobTimeline;
import com.sevalink.sevalinkbackend.model.Quotation;
import com.sevalink.sevalinkbackend.model.Worker;
import com.sevalink.sevalinkbackend.repository.JobPostRepository;
import com.sevalink.sevalinkbackend.repository.JobTimelineRepository;
import com.sevalink.sevalinkbackend.repository.QuotationRepository;
import com.sevalink.sevalinkbackend.repository.WorkerRepository;
import com.sevalink.sevalinkbackend.model.Notification;
import com.sevalink.sevalinkbackend.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class QuotationService {

    @Autowired
    private QuotationRepository quotationRepository;

    @Autowired
    private JobPostRepository jobPostRepository;

    @Autowired
    private JobTimelineRepository jobTimelineRepository;

    @Autowired
    private WorkerRepository workerRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    // Worker sends a quotation
    public Quotation sendQuotation(Quotation quotation) {
        // Load full entities from DB so nested getUser()/getClient() work correctly
        Worker worker = workerRepository.findById(quotation.getWorker().getId())
                .orElseThrow(() -> new RuntimeException("Worker not found"));
        JobPost jobPost = jobPostRepository.findById(quotation.getJobPost().getId())
                .orElseThrow(() -> new RuntimeException("Job not found"));

        if (!"OPEN".equals(jobPost.getStatus())) {
            throw new RuntimeException("Cannot send a quotation. This job is no longer open.");
        }

        quotationRepository.findByJobPostIdAndWorkerId(
                jobPost.getId(),
                worker.getId())
                .ifPresent(q -> {
                    throw new RuntimeException("Already sent a quotation for this job");
                });

        quotation.setWorker(worker);
        quotation.setJobPost(jobPost);

        Quotation saved = quotationRepository.save(quotation);

        JobTimeline timeline = new JobTimeline();
        timeline.setJobPost(jobPost);
        timeline.setStatus("QUOTE_RECEIVED");
        timeline.setNote("Quote received from worker");
        jobTimelineRepository.save(timeline);

        // Notify Client about new quote
        Notification notification = new Notification();
        notification.setUser(jobPost.getClient());
        notification.setJobPost(jobPost);
        notification.setTitle("New Quote Received");
        notification.setMessage("You have received a new quote from " + worker.getUser().getFullName() + " for your job.");
        notificationRepository.save(notification);

        return saved;
    }

    // Client sees all quotations for a job
    public List<Quotation> getJobQuotations(Long jobPostId) {
        return quotationRepository.findByJobPostIdOrderByProposedPriceAsc(jobPostId);
    }

    // Worker sees their sent quotations
    public List<Quotation> getWorkerQuotations(Long workerId) {
        List<Quotation> quotations = quotationRepository.findByWorkerIdOrderByCreatedAtDesc(workerId);
        
        // Fetch worker coordinates
        Worker worker = workerRepository.findById(workerId).orElse(null);
        Double workerLat = worker != null ? worker.getLatitude() : null;
        Double workerLng = worker != null ? worker.getLongitude() : null;
        
        return quotations.stream()
                .map(q -> getMaskedQuotationCopy(q, workerLat, workerLng))
                .collect(Collectors.toList());
    }

    // Client accepts a quotation
    public Quotation acceptQuotation(Long quotationId) {
        Quotation quotation = quotationRepository.findById(quotationId)
                .orElseThrow(() -> new RuntimeException("Quotation not found"));

        if (!"PENDING".equals(quotation.getStatus())) {
            throw new RuntimeException("Quotation is already " + quotation.getStatus().toLowerCase());
        }

        quotation.setStatus("ACCEPTED");
        quotationRepository.save(quotation);

        // Reject all other quotations for same job
        List<Quotation> others = quotationRepository
                .findByJobPostIdOrderByProposedPriceAsc(quotation.getJobPost().getId());
        for (Quotation other : others) {
            if (!other.getId().equals(quotationId)) {
                other.setStatus("REJECTED");
                quotationRepository.save(other);
            }
        }

        // Update job status to ASSIGNED
        JobPost job = quotation.getJobPost();
        job.setStatus("ASSIGNED");
        jobPostRepository.save(job);

        // Update timeline
        JobTimeline timeline = new JobTimeline();
        timeline.setJobPost(job);
        timeline.setStatus("QUOTE_ACCEPTED");
        timeline.setNote("Client accepted a worker");
        jobTimelineRepository.save(timeline);

        // Notify Worker
        Notification notification = new Notification();
        notification.setUser(quotation.getWorker().getUser());
        notification.setJobPost(job);
        notification.setTitle("Quote Accepted");
        notification.setMessage("Your quote for " + job.getTitle() + " has been accepted!");
        notificationRepository.save(notification);

        return quotation;
    }

    // Client rejects a quotation
    public Quotation rejectQuotation(Long quotationId) {
        Quotation quotation = quotationRepository.findById(quotationId)
                .orElseThrow(() -> new RuntimeException("Quotation not found"));
        
        if (!"PENDING".equals(quotation.getStatus())) {
            throw new RuntimeException("Quotation is already " + quotation.getStatus().toLowerCase());
        }
        quotation.setStatus("REJECTED");
        Quotation saved = quotationRepository.save(quotation);

        // Notify Worker
        Notification notification = new Notification();
        notification.setUser(quotation.getWorker().getUser());
        notification.setJobPost(quotation.getJobPost());
        notification.setTitle("Quote Declined");
        notification.setMessage("Your quote for " + quotation.getJobPost().getTitle() + " was declined.");
        notificationRepository.save(notification);

        return saved;
    }

    // Get contact details after acceptance (phone reveal)
    public java.util.Map<String, Object> getContactDetails(Long quotationId) {
        Quotation quotation = quotationRepository.findById(quotationId)
                .orElseThrow(() -> new RuntimeException("Quotation not found"));

        if (!quotation.getStatus().equals("ACCEPTED")) {
            throw new RuntimeException("Contact details only available after acceptance");
        }

        java.util.Map<String, Object> contact = new java.util.HashMap<>();

        // Worker info (for client to see)
        java.util.Map<String, Object> workerContact = new java.util.HashMap<>();
        workerContact.put("name",   quotation.getWorker().getUser().getFullName());
        workerContact.put("phone",  quotation.getWorker().getUser().getPhoneNumber());
        workerContact.put("rating", quotation.getWorker().getRating());

        // Client info (for worker to see)
        java.util.Map<String, Object> clientContact = new java.util.HashMap<>();
        clientContact.put("name",     quotation.getJobPost().getClient().getFullName());
        clientContact.put("phone",    quotation.getJobPost().getClient().getPhoneNumber());
        clientContact.put("location", quotation.getJobPost().getLocationName());

        contact.put("worker",      workerContact);
        contact.put("client",      clientContact);
        contact.put("jobTitle",    quotation.getJobPost().getTitle());
        contact.put("agreedPrice", quotation.getProposedPrice());

        return contact;
    }

    private Quotation getMaskedQuotationCopy(Quotation original, Double workerLat, Double workerLng) {
        Quotation copy = new Quotation();
        copy.setId(original.getId());
        copy.setWorker(original.getWorker());
        copy.setMessage(original.getMessage());
        copy.setProposedPrice(original.getProposedPrice());
        copy.setEta(original.getEta());
        copy.setStatus(original.getStatus());
        copy.setCreatedAt(original.getCreatedAt());
        
        if ("ACCEPTED".equalsIgnoreCase(original.getStatus())) {
            // Keep exact location if accepted
            copy.setJobPost(original.getJobPost());
        } else {
            // Mask location if not accepted
            copy.setJobPost(getMaskedJobPostCopy(original.getJobPost(), workerLat, workerLng));
        }
        return copy;
    }

    private JobPost getMaskedJobPostCopy(JobPost original, Double workerLat, Double workerLng) {
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
        
        // Mask location
        copy.setLocationName(JobPostService.getApproximateLocation(original.getLocationName()));
        copy.setLatitude(null);
        copy.setLongitude(null);
        
        // Compute distance if worker coordinates are available
        if (workerLat != null && workerLng != null && original.getLatitude() != null && original.getLongitude() != null) {
            double dist = JobPostService.calculateDistanceKm(workerLat, workerLng, original.getLatitude(), original.getLongitude());
            copy.setDistanceKm(dist);
        }
        
        return copy;
    }
}
