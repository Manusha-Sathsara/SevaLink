package com.sevalink.sevalinkbackend.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "workers")
public class Worker {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne
    @JoinColumn(name = "category_id")
    private Category category;

    private String bio;

    @Column(name = "hourly_rate")
    private Double hourlyRate;

    private Double rating = 0.0;

    @Column(name = "total_jobs")
    private Integer totalJobs = 0;

    @Column(name = "is_available")
    private Boolean isAvailable = true;

    private Double latitude;
    private Double longitude;
}