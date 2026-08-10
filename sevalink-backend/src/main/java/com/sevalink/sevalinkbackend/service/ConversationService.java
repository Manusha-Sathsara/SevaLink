package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.ChatDTOs.*;
import com.sevalink.sevalinkbackend.model.Conversation;
import com.sevalink.sevalinkbackend.model.Message;
import com.sevalink.sevalinkbackend.repository.ConversationRepository;
import com.sevalink.sevalinkbackend.repository.MessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ConversationService {

    private final ConversationRepository conversationRepository;
    private final MessageRepository      messageRepository;

    @Transactional
    public ConversationResponse createOrGetConversation(CreateConversationRequest req) {
        Conversation conv = conversationRepository
                .findByClientIdAndWorkerId(req.getClientId(), req.getWorkerId())
                .orElseGet(() -> conversationRepository.save(
                        Conversation.builder()
                                .clientId(req.getClientId())
                                .workerId(req.getWorkerId())
                                .build()
                ));
        return toResponse(conv, req.getClientId());
    }

    @Transactional(readOnly = true)
    public List<ConversationResponse> getConversationsForUser(Long userId) {
        return conversationRepository.findAllByUserId(userId)
                .stream()
                .map(c -> toResponse(c, userId))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ConversationResponse getConversationById(Long conversationId) {
        Conversation conv = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new RuntimeException("Conversation not found: " + conversationId));
        return toResponse(conv, null);
    }

    private ConversationResponse toResponse(Conversation conv, Long currentUserId) {
        Message lastMsg = messageRepository
                .findTopByConversation_IdOrderByCreatedAtDesc(conv.getId())
                .orElse(null);

        long unread = currentUserId != null
                ? messageRepository.countByConversation_IdAndReceiverIdAndIsReadFalse(
                conv.getId(), currentUserId)
                : 0L;

        return ConversationResponse.builder()
                .id(conv.getId())
                .clientId(conv.getClientId())
                .workerId(conv.getWorkerId())
                .lastMessage(lastMsg != null ? lastMsg.getMessageText() : null)
                .lastMessageTime(lastMsg != null ? lastMsg.getCreatedAt() : null)
                .unreadCount(unread)
                .createdAt(conv.getCreatedAt())
                .updatedAt(conv.getUpdatedAt())
                .build();
    }
}