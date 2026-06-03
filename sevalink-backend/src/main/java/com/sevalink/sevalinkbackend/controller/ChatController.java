package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.dto.ApiResponse;
import com.sevalink.sevalinkbackend.dto.ChatRoomResponse;
import com.sevalink.sevalinkbackend.model.ChatMessage;
import com.sevalink.sevalinkbackend.model.ChatRoom;
import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import com.sevalink.sevalinkbackend.service.ChatService;
import lombok.Data;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*")
public class ChatController {

    @Autowired
    private ChatService chatService;

    @Autowired
    private UserRepository userRepository;

    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()
                || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new RuntimeException("Unauthorized");
        }
        String email = authentication.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    @PostMapping("/room")
    public ResponseEntity<ApiResponse<ChatRoom>> getOrCreateRoom(@RequestBody Map<String, Long> request) {
        try {
            User currentUser = getCurrentUser();
            Long recipientId = request.get("recipientId");
            if (recipientId == null) {
                return ResponseEntity.badRequest().body(ApiResponse.error("recipientId is required"));
            }
            ChatRoom room = chatService.getOrCreateChatRoom(currentUser.getId(), recipientId);
            return ResponseEntity.ok(ApiResponse.success("Chat room initialized", room));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/rooms")
    public ResponseEntity<ApiResponse<List<ChatRoomResponse>>> getChatRooms() {
        try {
            User currentUser = getCurrentUser();
            List<ChatRoomResponse> rooms = chatService.getChatRoomsForUser(currentUser.getId());
            return ResponseEntity.ok(ApiResponse.success("Chat rooms retrieved", rooms));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/room/{roomId}/messages")
    public ResponseEntity<ApiResponse<List<ChatMessage>>> getMessages(@PathVariable Long roomId) {
        try {
            User currentUser = getCurrentUser();
            List<ChatMessage> messages = chatService.getChatMessages(roomId, currentUser.getId());
            return ResponseEntity.ok(ApiResponse.success("Messages retrieved", messages));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PostMapping("/message")
    public ResponseEntity<ApiResponse<ChatMessage>> sendMessage(@RequestBody MessageRequest request) {
        try {
            User currentUser = getCurrentUser();
            ChatMessage message = chatService.sendMessage(
                    request.getChatRoomId(),
                    currentUser.getId(),
                    request.getRecipientId(),
                    request.getContent()
            );
            return ResponseEntity.ok(ApiResponse.success("Message sent successfully", message));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse<Long>> getUnreadCount() {
        try {
            User currentUser = getCurrentUser();
            long count = chatService.getGlobalUnreadCount(currentUser.getId());
            return ResponseEntity.ok(ApiResponse.success("Unread count retrieved", count));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @Data
    public static class MessageRequest {
        private Long chatRoomId;
        private Long recipientId;
        private String content;
    }
}
