package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {
    List<ChatMessage> findByChatRoomIdOrderByTimestampAsc(Long chatRoomId);
    
    long countByRecipientIdAndIsReadFalse(Long recipientId);
    
    List<ChatMessage> findByChatRoomIdAndRecipientIdAndIsReadFalse(Long chatRoomId, Long recipientId);

    long countByChatRoomIdAndRecipientIdAndIsReadFalse(Long chatRoomId, Long recipientId);

    Optional<ChatMessage> findFirstByChatRoomIdOrderByTimestampDesc(Long chatRoomId);
}
