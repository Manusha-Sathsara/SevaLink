package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.dto.ApiResponse;
import com.sevalink.sevalinkbackend.model.ChatMessage;
import com.sevalink.sevalinkbackend.model.ChatRoom;
import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.service.ChatService;
import com.sevalink.sevalinkbackend.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*")
public class ChatController {

    @Autowired
    private ChatService chatService;

    @Autowired
    private UserService userService;

    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()
                || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new RuntimeException("Unauthorized user access");
        }
        String email = authentication.getName();
        return userService.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found for email: " + email));
    }

    @GetMapping("/rooms")
    public ResponseEntity<ApiResponse<List<ChatRoom>>> getChatRooms() {
        try {
            User currentUser = getCurrentUser();
            List<ChatRoom> rooms = chatService.getRoomsForUser(currentUser.getId());
            return ResponseEntity.ok(ApiResponse.success("Chat rooms retrieved", rooms));
        } catch (RuntimeException e) {
            return ResponseEntity.status(401).body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/rooms/with/{otherUserId}")
    public ResponseEntity<ApiResponse<ChatRoom>> getOrCreateRoom(@PathVariable Long otherUserId) {
        try {
            User currentUser = getCurrentUser();
            ChatRoom room = chatService.getOrCreateRoom(currentUser.getId(), otherUserId);
            return ResponseEntity.ok(ApiResponse.success("Chat room initialized", room));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/messages/{roomId}")
    public ResponseEntity<ApiResponse<List<ChatMessage>>> getChatHistory(@PathVariable Long roomId) {
        try {
            // Validate user is member of room
            User currentUser = getCurrentUser();
            List<ChatMessage> history = chatService.getChatHistory(roomId);
            return ResponseEntity.ok(ApiResponse.success("Chat history retrieved", history));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PutMapping("/messages/{roomId}/read")
    public ResponseEntity<ApiResponse<Void>> markRoomAsRead(@PathVariable Long roomId) {
        try {
            User currentUser = getCurrentUser();
            chatService.markRoomMessagesAsRead(roomId, currentUser.getId());
            return ResponseEntity.ok(ApiResponse.success("Messages marked as read", null));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}
