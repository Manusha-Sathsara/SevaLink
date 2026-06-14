package com.sevalink.sevalinkbackend.websocket;

import com.sevalink.sevalinkbackend.dto.ChatMessageDto;
import com.sevalink.sevalinkbackend.model.ChatMessage;
import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import com.sevalink.sevalinkbackend.service.ChatService;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;

/**
 * Handles inbound STOMP messages routed through /app/chat.send.
 *
 * Flow:
 *  1. Flutter sends STOMP frame to /app/chat.send with WsMessageRequest payload
 *  2. This controller persists the message via ChatService (which also broadcasts)
 *  3. ChatService broadcasts the saved message to /topic/messages/{roomId}
 *  4. All subscribers in that room receive the message instantly
 */
@Slf4j
@Controller
public class ChatWebSocketController {

    @Autowired
    private ChatService chatService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    /**
     * Receives a send-message request from a STOMP client.
     * The message is persisted via ChatService and broadcast back via the service.
     *
     * @param request   the payload sent by Flutter
     * @param authentication  the authenticated Spring Security principal (set by the channel interceptor)
     */
    @MessageMapping("/chat.send")
    public void handleSendMessage(@Payload WsMessageRequest request,
                                  Authentication authentication) {
        try {
            // Resolve the sender from the authenticated principal (email)
            String senderEmail = authentication != null ? authentication.getName() : null;
            if (senderEmail == null) {
                log.warn("Unauthenticated WebSocket message dropped");
                return;
            }

            User sender = userRepository.findByEmail(senderEmail)
                    .orElseThrow(() -> new RuntimeException("Sender not found: " + senderEmail));

            // Persist message + broadcast via ChatService
            ChatMessage saved = chatService.sendMessage(
                    request.getChatRoomId(),
                    sender.getId(),
                    request.getRecipientId(),
                    request.getContent(),
                    request.getMessageType()
            );

            log.debug("WS message sent: roomId={} sender={}", request.getChatRoomId(), senderEmail);

        } catch (Exception e) {
            log.error("Error handling WebSocket message: {}", e.getMessage(), e);
        }
    }

    /** Payload sent by Flutter clients over WebSocket */
    @Data
    public static class WsMessageRequest {
        private Long chatRoomId;
        private Long recipientId;
        private String content;
        private String messageType = "TEXT";
    }
}
