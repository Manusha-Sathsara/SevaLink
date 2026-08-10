package com.sevalink.sevalinkbackend.dto;

import com.sevalink.sevalinkbackend.model.Message;
import lombok.*;

import java.time.OffsetDateTime;

public class ChatDTOs {

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class CreateConversationRequest {
        private Long clientId;
        private Long workerId;
    }

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class SendMessageRequest {
        private Long conversationId;
        private Long senderId;
        private Long receiverId;
        private String messageText;
        private Message.MessageType messageType;
    }

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class ConversationResponse {
        private Long id;
        private Long clientId;
        private Long workerId;
        private String lastMessage;
        private OffsetDateTime lastMessageTime;
        private long unreadCount;
        private OffsetDateTime createdAt;
        private OffsetDateTime updatedAt;
    }

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class MessageResponse {
        private Long id;
        private Long conversationId;
        private Long senderId;
        private Long receiverId;
        private String messageText;
        private Message.MessageType messageType;
        private boolean isRead;
        private OffsetDateTime createdAt;
    }

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class WebSocketMessage {
        private Long conversationId;
        private MessageResponse message;
    }

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class MarkReadRequest {
        private Long conversationId;
        private Long receiverId;
    }
}