package com.sevalink.sevalinkbackend.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "job_posts")
public class JobPost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "client_id")
    private User client;

    @ManyToOne
    @JoinColumn(name = "category_id")
    private Category category;

    @Column(nullable = false)
    private String title;

    private String description;

    // Location
    private Double latitude;
    private Double longitude;

    @Column(name = "location_name")
    private String locationName; // "Dehiwala, Colombo"

    // Budget range
    @Column(name = "budget_min")
    private Double budgetMin;

    @Column(name = "budget_max")
    private Double budgetMax;

    // Urgent or Flexible
    private String urgency = "FLEXIBLE";

    // Photos (stored as comma separated URLs)
    private String photos;

    // OPEN, ASSIGNED, COMPLETED, CANCELLED
    private String status = "OPEN";

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
}