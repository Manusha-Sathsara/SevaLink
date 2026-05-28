package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.model.JobPost;
import com.sevalink.sevalinkbackend.model.JobTimeline;
import com.sevalink.sevalinkbackend.model.Quotation;
import com.sevalink.sevalinkbackend.repository.JobPostRepository;
import com.sevalink.sevalinkbackend.repository.JobTimelineRepository;
import com.sevalink.sevalinkbackend.repository.QuotationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class QuotationService {

    @Autowired
    private QuotationRepository quotationRepository;

    @Autowired
    private JobPostRepository jobPostRepository;

    @Autowired
    private JobTimelineRepository jobTimelineRepository;

    // Worker sends a quotation
    public Quotation sendQuotation(Quotation quotation) {
        quotationRepository.findByJobPostIdAndWorkerId(
                        quotation.getJobPost().getId(),
                        quotation.getWorker().getId())
                .ifPresent(q -> {
                    throw new RuntimeException("Already sent a quotation for this job");
                });

        Quotation saved = quotationRepository.save(quotation);

        JobTimeline timeline = new JobTimeline();
        timeline.setJobPost(quotation.getJobPost());
        timeline.setStatus("QUOTE_RECEIVED");
        timeline.setNote("Quote received from worker");
        jobTimelineRepository.save(timeline);

        return saved;
    }

    // Client sees all quotations for a job
    public List<Quotation> getJobQuotations(Long jobPostId) {
        return quotationRepository.findByJobPostIdOrderByProposedPriceAsc(jobPostId);
    }

    // Worker sees their sent quotations
    public List<Quotation> getWorkerQuotations(Long workerId) {
        return quotationRepository.findByWorkerIdOrderByCreatedAtDesc(workerId);
    }

    // Client accepts a quotation
    public Quotation acceptQuotation(Long quotationId) {
        Quotation quotation = quotationRepository.findById(quotationId)
                .orElseThrow(() -> new RuntimeException("Quotation not found"));

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

        return quotation;
    }

    // Client rejects a quotation
    public Quotation rejectQuotation(Long quotationId) {
        Quotation quotation = quotationRepository.findById(quotationId)
                .orElseThrow(() -> new RuntimeException("Quotation not found"));
        quotation.setStatus("REJECTED");
        return quotationRepository.save(quotation);
    }
}
