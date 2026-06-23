package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.Quotation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface QuotationRepository extends JpaRepository<Quotation, Long> {

    List<Quotation> findByJobPostIdOrderByProposedPriceAsc(Long jobPostId);

    List<Quotation> findByWorkerIdOrderByCreatedAtDesc(Long workerId);

    Optional<Quotation> findByJobPostIdAndWorkerId(Long jobPostId, Long workerId);

    Optional<Quotation> findByJobPostIdAndStatus(Long jobPostId, String status);
}