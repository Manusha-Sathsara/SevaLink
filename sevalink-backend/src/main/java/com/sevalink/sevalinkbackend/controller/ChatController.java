package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.dto.*;
import com.sevalink.sevalinkbackend.service.ChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import com.sevalink.sevalinkbackend.service.FileStorageService;
import java.util.Map;
import java.util.List;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*")
public class ChatController {

    @Autowired
    private ChatService chatService;

    private String getCurrentUserEmail() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()
                || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new RuntimeException("Unauthorized");
        }
        return authentication.getName();
    }

    @PostMapping("/send")
    public ResponseEntity<ApiResponse<ChatMessageDto>> sendMessage(@RequestBody SendMessageRequest request) {
        try {
            String email = getCurrentUserEmail();
            ChatMessageDto message = chatService.sendMessage(email, request);
            return ResponseEntity.ok(ApiResponse.success("Message sent", message));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/conversation/{otherUserId}")
    public ResponseEntity<ApiResponse<List<ChatMessageDto>>> getConversation(@PathVariable Long otherUserId) {
        try {
            String email = getCurrentUserEmail();
            List<ChatMessageDto> messages = chatService.getConversation(email, otherUserId);
            return ResponseEntity.ok(ApiResponse.success("Conversation fetched", messages));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/conversations")
    public ResponseEntity<ApiResponse<List<ChatConversationDto>>> getConversations() {
        try {
            String email = getCurrentUserEmail();
            List<ChatConversationDto> conversations = chatService.getConversations(email);
            return ResponseEntity.ok(ApiResponse.success("Conversations fetched", conversations));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @Autowired
    private FileStorageService fileStorageService;

    @PostMapping("/upload")
    public ResponseEntity<?> uploadAttachment(@RequestParam("file") MultipartFile file) {
        try {
            String fileName = fileStorageService.storeFile(file);
            String fileDownloadUri = org.springframework.web.servlet.support.ServletUriComponentsBuilder.fromCurrentContextPath()
                    .path("/api/public/uploads/")
                    .path(fileName)
                    .toUriString();
            return ResponseEntity.ok(Map.of("url", fileDownloadUri));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
