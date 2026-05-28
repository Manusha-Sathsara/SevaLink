package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.ChatMessage;
import com.sevalink.sevalinkbackend.model.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {
    List<ChatMessage> findByChatRoomOrderByTimestampAsc(ChatRoom chatRoom);

    @Transactional
    @Modifying
    @Query("UPDATE ChatMessage m SET m.isRead = true WHERE m.chatRoom = :chatRoom AND m.recipient.id = :recipientId AND m.isRead = false")
    void markMessagesAsRead(@Param("chatRoom") ChatRoom chatRoom, @Param("recipientId") Long recipientId);
}
