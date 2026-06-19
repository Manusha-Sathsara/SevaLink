package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.ChatDTOs.*;
import com.sevalink.sevalinkbackend.model.Conversation;
import com.sevalink.sevalinkbackend.model.Message;
import com.sevalink.sevalinkbackend.repository.ConversationRepository;
import com.sevalink.sevalinkbackend.repository.MessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MessageService {

    private final MessageRepository      messageRepository;
    private final ConversationRepository conversationRepository;
    private final SimpMessagingTemplate  messagingTemplate;

    @Transactional
    public MessageResponse sendMessage(SendMessageRequest req) {
        Conversation conv = conversationRepository.findById(req.getConversationId())
                .orElseThrow(() -> new RuntimeException(
                        "Conversation not found: " + req.getConversationId()));

        Message saved = messageRepository.save(
                Message.builder()
                        .conversation(conv)
                        .senderId(req.getSenderId())
                        .receiverId(req.getReceiverId())
                        .messageText(req.getMessageText())
                        .messageType(req.getMessageType() != null
                                ? req.getMessageType()
                                : Message.MessageType.TEXT)
                        .isRead(false)
                        .build()
        );

        MessageResponse response = toResponse(saved);

        messagingTemplate.convertAndSend(
                "/topic/messages/" + conv.getId(),
                WebSocketMessage.builder()
                        .conversationId(conv.getId())
                        .message(response)
                        .build()
        );

        return response;
    }

    @Transactional(readOnly = true)
    public List<MessageResponse> getMessages(Long conversationId) {
        return messageRepository
                .findByConversation_IdOrderByCreatedAtAsc(conversationId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public int markMessagesAsRead(Long conversationId, Long receiverId) {
        int updated = messageRepository.markAllAsRead(conversationId, receiverId);

        if (updated > 0) {
            messagingTemplate.convertAndSend(
                    "/topic/read/" + conversationId,
                    Map.of(
                            "conversationId", conversationId,
                            "receiverId",     receiverId,
                            "markedRead",     updated
                    )
            );
        }
        return updated;
    }

    private MessageResponse toResponse(Message m) {
        return MessageResponse.builder()
                .id(m.getId())
                .conversationId(m.getConversation().getId())
                .senderId(m.getSenderId())
                .receiverId(m.getReceiverId())
                .messageText(m.getMessageText())
                .messageType(m.getMessageType())
                .isRead(m.isRead())
                .createdAt(m.getCreatedAt())
                .build();
    }
}