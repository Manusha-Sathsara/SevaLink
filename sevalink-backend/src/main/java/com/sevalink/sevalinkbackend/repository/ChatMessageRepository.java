package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    @Query("SELECT m FROM ChatMessage m WHERE " +
            "(m.sender.id = :userId1 AND m.receiver.id = :userId2) OR " +
            "(m.sender.id = :userId2 AND m.receiver.id = :userId1) " +
            "ORDER BY m.createdAt ASC")
    List<ChatMessage> findConversation(@Param("userId1") Long userId1, @Param("userId2") Long userId2);

    @Query("SELECT DISTINCT CASE WHEN m.sender.id = :userId THEN m.receiver.id ELSE m.sender.id END " +
            "FROM ChatMessage m WHERE m.sender.id = :userId OR m.receiver.id = :userId")
    List<Long> findConversationPartnerIds(@Param("userId") Long userId);

    @Query("SELECT m FROM ChatMessage m WHERE m.id IN (" +
            "SELECT MAX(m2.id) FROM ChatMessage m2 WHERE " +
            "(m2.sender.id = :userId AND m2.receiver.id = :partnerId) OR " +
            "(m2.sender.id = :partnerId AND m2.receiver.id = :userId))")
    ChatMessage findLastMessage(@Param("userId") Long userId, @Param("partnerId") Long partnerId);

    @Query("SELECT COUNT(m) FROM ChatMessage m WHERE m.receiver.id = :userId AND m.sender.id = :partnerId AND m.isRead = false")
    long countUnreadMessages(@Param("userId") Long userId, @Param("partnerId") Long partnerId);
}
