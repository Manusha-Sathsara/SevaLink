package com.sevalink.sevalinkbackend.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "quotations")
public class Quotation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "job_post_id")
    private JobPost jobPost;

    @ManyToOne
    @JoinColumn(name = "worker_id")
    private Worker worker;

    private String message;

    @Column(name = "proposed_price")
    private Double proposedPrice;

    private String eta;

    private String status = "PENDING"; // PENDING, ACCEPTED, REJECTED

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
}
