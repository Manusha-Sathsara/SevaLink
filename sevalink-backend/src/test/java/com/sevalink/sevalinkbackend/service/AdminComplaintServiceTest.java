package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.AdminComplaintDto;
import com.sevalink.sevalinkbackend.model.Complaint;
import com.sevalink.sevalinkbackend.model.JobPost;
import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.repository.ComplaintRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminComplaintServiceTest {

    @Mock
    private ComplaintRepository complaintRepository;

    @InjectMocks
    private AdminComplaintService adminComplaintService;

    @Test
    void updateComplaintStatusPersistsStatusAndReturnsUpdatedDto() {
        Complaint complaint = new Complaint();
        complaint.setId(1L);
        complaint.setDescription("This is a fake job posting");
        complaint.setCreatedAt(LocalDateTime.now());
        complaint.setJobPost(new JobPost());
        complaint.setFiledBy(new User());

        when(complaintRepository.findById(1L)).thenReturn(Optional.of(complaint));
        when(complaintRepository.save(any(Complaint.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AdminComplaintDto updated = adminComplaintService.updateComplaintStatus(1L, "Resolved");

        assertEquals("Resolved", updated.getStatus());
        verify(complaintRepository).save(any(Complaint.class));
    }
}
