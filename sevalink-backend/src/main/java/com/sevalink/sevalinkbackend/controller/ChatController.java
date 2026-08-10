package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.dto.ChatDTOs.*;
import com.sevalink.sevalinkbackend.service.ConversationService;
import com.sevalink.sevalinkbackend.service.MessageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ConversationService conversationService;
    private final MessageService      messageService;

    @PostMapping("/conversations")
    public ResponseEntity<ConversationResponse> createConversation(
            @RequestBody CreateConversationRequest request) {
        return ResponseEntity.ok(conversationService.createOrGetConversation(request));
    }

    @GetMapping("/conversations/{userId}")
    public ResponseEntity<List<ConversationResponse>> getConversations(
            @PathVariable Long userId) {
        return ResponseEntity.ok(conversationService.getConversationsForUser(userId));
    }

    @GetMapping("/conversation/{conversationId}")
    public ResponseEntity<ConversationResponse> getConversation(
            @PathVariable Long conversationId) {
        return ResponseEntity.ok(conversationService.getConversationById(conversationId));
    }

    @PostMapping("/messages")
    public ResponseEntity<MessageResponse> sendMessage(
            @RequestBody SendMessageRequest request) {
        return ResponseEntity.ok(messageService.sendMessage(request));
    }

    @GetMapping("/messages/{conversationId}")
    public ResponseEntity<List<MessageResponse>> getMessages(
            @PathVariable Long conversationId) {
        return ResponseEntity.ok(messageService.getMessages(conversationId));
    }

    @PutMapping("/messages/read")
    public ResponseEntity<Void> markAsRead(@RequestBody MarkReadRequest request) {
        messageService.markMessagesAsRead(request.getConversationId(), request.getReceiverId());
        return ResponseEntity.noContent().build();
    }
}