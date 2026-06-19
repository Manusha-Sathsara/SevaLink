package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, Long> {

    @Query("""
        SELECT c FROM Conversation c
        WHERE c.clientId = :userId OR c.workerId = :userId
        ORDER BY c.updatedAt DESC
        """)
    List<Conversation> findAllByUserId(@Param("userId") Long userId);

    Optional<Conversation> findByClientIdAndWorkerId(Long clientId, Long workerId);
}
