package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {

    List<Message> findByConversation_IdOrderByCreatedAtAsc(Long conversationId);

    Optional<Message> findTopByConversation_IdOrderByCreatedAtDesc(Long conversationId);

    long countByConversation_IdAndReceiverIdAndIsReadFalse(Long conversationId, Long receiverId);

    @Modifying
    @Query("""
        UPDATE Message m SET m.isRead = true
        WHERE m.conversation.id = :conversationId
          AND m.receiverId = :receiverId
          AND m.isRead = false
        """)
    int markAllAsRead(@Param("conversationId") Long conversationId,
                      @Param("receiverId")     Long receiverId);
}