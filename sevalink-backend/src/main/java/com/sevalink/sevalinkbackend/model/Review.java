package com.sevalink.sevalinkbackend.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "reviews")
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "client_id")
    private User client;

    @ManyToOne
    @JoinColumn(name = "worker_id")
    private Worker worker;

    @ManyToOne
    @JoinColumn(name = "job_post_id")
    private JobPost jobPost;

    private Integer rating;

    private String comment;

    /**
     * Comma-separated list of uploaded review photo file names (relative to /uploads/).
     * Example: "uuid1.jpg,uuid2.jpg"
     */
    @Column(name = "photo_urls", length = 1024)
    private String photoUrls;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
}
