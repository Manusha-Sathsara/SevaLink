package com.sevalink.sevalinkbackend.dto;

import com.sevalink.sevalinkbackend.model.ChatMessage;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Flat DTO used for WebSocket broadcasts.
 * Avoids circular JSON serialization caused by JPA bidirectional relationships.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatMessageDto {

    private Long id;
    private Long chatRoomId;
    private Long senderId;
    private String senderName;
    private Long recipientId;
    private String recipientName;
    private String content;
    private String messageType;   // "TEXT" | "IMAGE"
    private Boolean isRead;
    private LocalDateTime timestamp;

    /** Converts a persisted ChatMessage entity into a safe broadcast DTO. */
    public static ChatMessageDto from(ChatMessage msg) {
        return ChatMessageDto.builder()
                .id(msg.getId())
                .chatRoomId(msg.getChatRoom().getId())
                .senderId(msg.getSender().getId())
                .senderName(msg.getSender().getFullName())
                .recipientId(msg.getRecipient().getId())
                .recipientName(msg.getRecipient().getFullName())
                .content(msg.getContent())
                .messageType(msg.getMessageType().name())
                .isRead(msg.getIsRead())
                .timestamp(msg.getTimestamp())
                .build();
    }
}
