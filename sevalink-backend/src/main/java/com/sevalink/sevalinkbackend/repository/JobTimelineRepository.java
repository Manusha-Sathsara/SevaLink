package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.JobTimeline;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface JobTimelineRepository extends JpaRepository<JobTimeline, Long> {

    List<JobTimeline> findByJobPostIdOrderByUpdatedAtAsc(Long jobPostId);
}