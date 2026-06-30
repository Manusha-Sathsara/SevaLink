package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.Complaint;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ComplaintRepository extends JpaRepository<Complaint, Long> {
    void deleteByJobPostId(Long jobPostId);
}
