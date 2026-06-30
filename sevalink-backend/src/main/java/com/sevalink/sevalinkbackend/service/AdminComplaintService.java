package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.AdminComplaintDto;
import com.sevalink.sevalinkbackend.model.Complaint;
import com.sevalink.sevalinkbackend.repository.ComplaintRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminComplaintService {

    @Autowired
    private ComplaintRepository complaintRepository;

    public List<AdminComplaintDto> getAdminComplaints() {
        return complaintRepository.findAll().stream()
                .sorted(Comparator.comparing(Complaint::getCreatedAt).reversed())
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public AdminComplaintDto updateComplaintStatus(Long complaintId, String newStatus) {
        Complaint complaint = complaintRepository.findById(complaintId)
                .orElseThrow(() -> new IllegalArgumentException("Complaint not found: " + complaintId));

        String normalizedStatus = newStatus == null ? "Pending" : newStatus.trim();
        if (normalizedStatus.isBlank()) {
            normalizedStatus = "Pending";
        }

        complaint.setStatus(normalizedStatus);
        return toDto(complaintRepository.save(complaint));
    }

    private AdminComplaintDto toDto(Complaint complaint) {
        String description = complaint.getDescription() == null ? "" : complaint.getDescription();
        String category = inferCategory(description);
        String priority = inferPriority(category, description);

        String resolvedStatus = complaint.getStatus();
        if (resolvedStatus == null || resolvedStatus.isBlank()) {
            resolvedStatus = priority.equals("High") ? "Investigating" : "Pending";
        }

        return AdminComplaintDto.builder()
                .id(complaint.getId())
                .jobId(complaint.getJobPost() != null ? complaint.getJobPost().getId() : null)
                .jobTitle(complaint.getJobPost() != null ? complaint.getJobPost().getTitle() : "Unknown job")
                .filedByName(complaint.getFiledBy() != null ? complaint.getFiledBy().getFullName() : "Unknown")
                .filedByEmail(complaint.getFiledBy() != null ? complaint.getFiledBy().getEmail() : "")
                .description(description)
                .category(category)
                .priority(priority)
                .status(resolvedStatus)
                .createdAt(complaint.getCreatedAt())
                .build();
    }

    private String inferCategory(String description) {
        String text = description.toLowerCase();
        if (text.contains("payment") || text.contains("refund") || text.contains("money")) {
            return "Payment Issues";
        }
        if (text.contains("fake") || text.contains("fraud") || text.contains("scam")) {
            return "Fraud";
        }
        if (text.contains("harass") || text.contains("abuse") || text.contains("threat")) {
            return "Harassment";
        }
        if (text.contains("job") || text.contains("work") || text.contains("service")) {
            return "Fake Jobs";
        }
        return "General";
    }

    private String inferPriority(String category, String description) {
        String text = description.toLowerCase();
        if (category.equals("Fraud") || text.contains("scam") || text.contains("fake") || text.contains("threat")) {
            return "High";
        }
        if (category.equals("Payment Issues") || text.contains("refund") || text.contains("money")) {
            return "Medium";
        }
        return "Low";
    }
}
