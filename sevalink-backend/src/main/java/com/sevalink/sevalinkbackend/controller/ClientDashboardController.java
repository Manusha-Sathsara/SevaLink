package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.dto.ClientDashboardResponse;
import com.sevalink.sevalinkbackend.service.ClientDashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/client")
@CrossOrigin(origins = "*")
public class ClientDashboardController {

    @Autowired
    private ClientDashboardService dashboardService;

    // GET http://localhost:8080/api/client/dashboard
    @GetMapping("/dashboard")
    public ResponseEntity<ClientDashboardResponse> getDashboard() {
        return ResponseEntity.ok(dashboardService.getDashboardData());
    }
}
