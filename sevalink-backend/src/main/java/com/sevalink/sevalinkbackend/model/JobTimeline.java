package com.sevalink.sevalinkbackend.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "job_timeline")
public class JobTimeline {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "job_post_id")
    private JobPost jobPost;

    private String status;
    // JOB_POSTED, QUOTE_RECEIVED, QUOTE_ACCEPTED,
    // WORKER_EN_ROUTE, JOB_ONGOING, JOB_DONE,
    // PAYMENT_DONE, REVIEW

    private String note;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();
}
