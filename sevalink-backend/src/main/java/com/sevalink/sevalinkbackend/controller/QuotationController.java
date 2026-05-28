package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.model.Quotation;
import com.sevalink.sevalinkbackend.service.QuotationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/quotations")
@CrossOrigin(origins = "*")
public class QuotationController {

    @Autowired
    private QuotationService quotationService;

    // Worker sends a quotation
    // POST http://localhost:8080/api/quotations
    @PostMapping
    public ResponseEntity<?> sendQuotation(@RequestBody Quotation quotation) {
        try {
            Quotation saved = quotationService.sendQuotation(quotation);
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // Client sees all quotations for a job
    // GET http://localhost:8080/api/quotations/job/1
    @GetMapping("/job/{jobPostId}")
    public List<Quotation> getJobQuotations(@PathVariable Long jobPostId) {
        return quotationService.getJobQuotations(jobPostId);
    }

    // Worker sees their sent quotations
    // GET http://localhost:8080/api/quotations/worker/1
    @GetMapping("/worker/{workerId}")
    public List<Quotation> getWorkerQuotations(@PathVariable Long workerId) {
        return quotationService.getWorkerQuotations(workerId);
    }

    // Client accepts a quotation
    // PUT http://localhost:8080/api/quotations/1/accept
    @PutMapping("/{id}/accept")
    public ResponseEntity<?> acceptQuotation(@PathVariable Long id) {
        try {
            Quotation accepted = quotationService.acceptQuotation(id);
            return ResponseEntity.ok(accepted);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // Client rejects a quotation
    // PUT http://localhost:8080/api/quotations/1/reject
    @PutMapping("/{id}/reject")
    public ResponseEntity<?> rejectQuotation(@PathVariable Long id) {
        try {
            Quotation rejected = quotationService.rejectQuotation(id);
            return ResponseEntity.ok(rejected);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}