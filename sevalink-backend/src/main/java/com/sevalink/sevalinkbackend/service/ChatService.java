package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.ChatMessageDto;
import com.sevalink.sevalinkbackend.dto.ChatRoomResponse;
import com.sevalink.sevalinkbackend.model.ChatMessage;
import com.sevalink.sevalinkbackend.model.ChatRoom;
import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.repository.ChatMessageRepository;
import com.sevalink.sevalinkbackend.repository.ChatRoomRepository;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Core chat service — handles room management, message persistence,
 * read-receipt marking, and real-time WebSocket broadcasts.
 */
@Slf4j
@Service
@Transactional
public class ChatService {

    @Autowired
    private ChatRoomRepository chatRoomRepository;

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * SimpMessagingTemplate — sends messages to a specific STOMP topic.
     * Spring injects this automatically when WebSocket is on the classpath.
     */
    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    // ── Room Management ────────────────────────────────────────────────────────

    public ChatRoom getOrCreateChatRoom(Long userId1, Long userId2) {
        User user1 = userRepository.findById(userId1)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId1));
        User user2 = userRepository.findById(userId2)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId2));

        // Enforce user1Id < user2Id to maintain DB uniqueness
        User firstUser  = user1.getId() < user2.getId() ? user1 : user2;
        User secondUser = user1.getId() < user2.getId() ? user2 : user1;

        Optional<ChatRoom> existing = chatRoomRepository
                .findByUser1IdAndUser2Id(firstUser.getId(), secondUser.getId());
        if (existing.isPresent()) return existing.get();

        ChatRoom chatRoom = new ChatRoom();
        chatRoom.setUser1(firstUser);
        chatRoom.setUser2(secondUser);
        chatRoom.setCreatedAt(LocalDateTime.now());
        chatRoom.setLastMessageAt(LocalDateTime.now());
        return chatRoomRepository.save(chatRoom);
    }

    public List<ChatRoomResponse> getChatRoomsForUser(Long userId) {
        List<ChatRoom> rooms = chatRoomRepository
                .findByUser1IdOrUser2IdOrderByLastMessageAtDesc(userId, userId);
        List<ChatRoomResponse> responses = new ArrayList<>();

        for (ChatRoom room : rooms) {
            User otherUser = room.getUser1().getId() == userId
                    ? room.getUser2() : room.getUser1();

            Optional<ChatMessage> lastMsgOpt =
                    chatMessageRepository.findFirstByChatRoomIdOrderByTimestampDesc(room.getId());
            String lastMessage = lastMsgOpt.map(ChatMessage::getContent).orElse("No messages yet");
            LocalDateTime lastMessageAt = lastMsgOpt.map(ChatMessage::getTimestamp)
                    .orElse(room.getLastMessageAt());

            long unreadCount = chatMessageRepository
                    .countByChatRoomIdAndRecipientIdAndIsReadFalse(room.getId(), userId);

            responses.add(new ChatRoomResponse(
                    room.getId(),
                    otherUser.getId(),
                    otherUser.getFullName(),
                    otherUser.getRole(),
                    lastMessage,
                    lastMessageAt,
                    unreadCount
            ));
        }
        return responses;
    }

    // ── Message Persistence + Broadcast ───────────────────────────────────────

    /**
     * Overload used by REST endpoint (ChatController) — defaults to TEXT type.
     */
    public ChatMessage sendMessage(Long chatRoomId, Long senderId,
                                   Long recipientId, String content) {
        return sendMessage(chatRoomId, senderId, recipientId, content, "TEXT");
    }

    /**
     * Core send method — persists message and broadcasts via WebSocket.
     *
     * @param messageTypeStr "TEXT" | "IMAGE" (case-insensitive; defaults to TEXT on unknown)
     */
    public ChatMessage sendMessage(Long chatRoomId, Long senderId,
                                   Long recipientId, String content,
                                   String messageTypeStr) {
        ChatRoom room = chatRoomRepository.findById(chatRoomId)
                .orElseThrow(() -> new RuntimeException("Chat room not found: " + chatRoomId));
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new RuntimeException("Sender not found: " + senderId));
        User recipient = userRepository.findById(recipientId)
                .orElseThrow(() -> new RuntimeException("Recipient not found: " + recipientId));

        ChatMessage.MessageType msgType;
        try {
            msgType = ChatMessage.MessageType.valueOf(
                    messageTypeStr != null ? messageTypeStr.toUpperCase() : "TEXT");
        } catch (IllegalArgumentException e) {
            msgType = ChatMessage.MessageType.TEXT;
        }

        ChatMessage message = new ChatMessage();
        message.setChatRoom(room);
        message.setSender(sender);
        message.setRecipient(recipient);
        message.setContent(content);
        message.setMessageType(msgType);
        message.setTimestamp(LocalDateTime.now());
        message.setIsRead(false);

        ChatMessage saved = chatMessageRepository.save(message);

        // Update room's last activity timestamp
        room.setLastMessageAt(LocalDateTime.now());
        chatRoomRepository.save(room);

        // ─── Real-Time Broadcast ──────────────────────────────────────────────
        // Convert to flat DTO (avoids circular JSON from JPA relations)
        ChatMessageDto dto = ChatMessageDto.from(saved);

        // Push to both participants' topic subscriptions
        String topic = "/topic/messages/" + chatRoomId;
        messagingTemplate.convertAndSend(topic, dto);
        log.debug("Broadcast to {}: msgId={}", topic, saved.getId());

        return saved;
    }

    // ── Read Receipts ──────────────────────────────────────────────────────────

    public List<ChatMessage> getChatMessages(Long chatRoomId, Long currentUserId) {
        // Mark unread messages addressed to the current user as read
        List<ChatMessage> unread = chatMessageRepository
                .findByChatRoomIdAndRecipientIdAndIsReadFalse(chatRoomId, currentUserId);
        unread.forEach(msg -> msg.setIsRead(true));
        if (!unread.isEmpty()) {
            chatMessageRepository.saveAll(unread);
        }
        return chatMessageRepository.findByChatRoomIdOrderByTimestampAsc(chatRoomId);
    }

    public long getGlobalUnreadCount(Long userId) {
        return chatMessageRepository.countByRecipientIdAndIsReadFalse(userId);
    }
}
