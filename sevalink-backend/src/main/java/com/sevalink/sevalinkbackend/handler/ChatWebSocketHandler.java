package com.sevalink.sevalinkbackend.handler;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.sevalink.sevalinkbackend.model.ChatMessage;
import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.security.JwtTokenProvider;
import com.sevalink.sevalinkbackend.service.ChatService;
import com.sevalink.sevalinkbackend.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import java.io.IOException;
import java.net.URI;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class ChatWebSocketHandler extends TextWebSocketHandler {

    private static final ConcurrentHashMap<Long, WebSocketSession> sessions = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper;

    @Autowired
    private ChatService chatService;

    @Autowired
    private UserService userService;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    public ChatWebSocketHandler() {
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        URI uri = session.getUri();
        if (uri == null) {
            session.close(CloseStatus.BAD_DATA);
            return;
        }

        String query = uri.getQuery();
        String token = null;
        if (query != null) {
            String[] params = query.split("&");
            for (String param : params) {
                String[] pair = param.split("=");
                if (pair.length > 1 && "token".equals(pair[0])) {
                    token = pair[1];
                    break;
                }
            }
        }

        if (token != null && jwtTokenProvider.validateToken(token)) {
            String email = jwtTokenProvider.getEmailFromToken(token);
            User user = userService.findByEmail(email).orElse(null);
            if (user != null) {
                session.getAttributes().put("userId", user.getId());
                session.getAttributes().put("userEmail", user.getEmail());
                sessions.put(user.getId(), session);
                return;
            }
        }

        // Close connection if token validation fails
        session.close(CloseStatus.BAD_DATA);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        Long senderId = (Long) session.getAttributes().get("userId");
        if (senderId == null) {
            session.close(CloseStatus.BAD_DATA);
            return;
        }

        String payload = message.getPayload();
        JsonNode jsonNode = objectMapper.readTree(payload);

        if (!jsonNode.has("recipientId") || !jsonNode.has("content")) {
            return;
        }

        long recipientId = jsonNode.get("recipientId").asLong();
        String content = jsonNode.get("content").asText();

        // Save message to DB (also handles ChatRoom creation if not exists)
        ChatMessage chatMessage = chatService.saveMessage(senderId, recipientId, content);

        // Prepare outbound message JSON
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("id", chatMessage.getId());
        responseMap.put("chatRoomId", chatMessage.getChatRoom().getId());
        responseMap.put("senderId", senderId);
        responseMap.put("recipientId", recipientId);
        responseMap.put("content", content);
        responseMap.put("timestamp", chatMessage.getTimestamp().toString());
        responseMap.put("isRead", chatMessage.getIsRead());

        String jsonResponse = objectMapper.writeValueAsString(responseMap);

        // Send to recipient if online
        WebSocketSession recipientSession = sessions.get(recipientId);
        if (recipientSession != null && recipientSession.isOpen()) {
            recipientSession.sendMessage(new TextMessage(jsonResponse));
        }

        // Send confirmation back to sender
        if (session.isOpen()) {
            session.sendMessage(new TextMessage(jsonResponse));
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        Long userId = (Long) session.getAttributes().get("userId");
        if (userId != null) {
            sessions.remove(userId);
        }
    }
}
