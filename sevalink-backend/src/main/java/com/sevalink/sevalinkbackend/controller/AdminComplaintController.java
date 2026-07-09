package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.dto.AdminComplaintDto;
import com.sevalink.sevalinkbackend.dto.ApiResponse;
import com.sevalink.sevalinkbackend.service.AdminComplaintService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminComplaintController {

    @Autowired
    private AdminComplaintService adminComplaintService;

    @GetMapping("/complaints")
    public ResponseEntity<ApiResponse<List<AdminComplaintDto>>> getComplaints() {
        List<AdminComplaintDto> complaints = adminComplaintService.getAdminComplaints();
        return ResponseEntity.ok(ApiResponse.success("Complaints loaded", complaints));
    }

    @PutMapping("/complaints/{id}/status")
    public ResponseEntity<ApiResponse<AdminComplaintDto>> updateComplaintStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> payload) {
        String status = payload.get("status");
        AdminComplaintDto updatedComplaint = adminComplaintService.updateComplaintStatus(id, status);
        return ResponseEntity.ok(ApiResponse.success("Complaint status updated", updatedComplaint));
    }
}
