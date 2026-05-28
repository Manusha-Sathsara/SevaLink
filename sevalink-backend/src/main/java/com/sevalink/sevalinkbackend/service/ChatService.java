package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.model.ChatMessage;
import com.sevalink.sevalinkbackend.model.ChatRoom;
import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.repository.ChatMessageRepository;
import com.sevalink.sevalinkbackend.repository.ChatRoomRepository;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class ChatService {

    @Autowired
    private ChatRoomRepository chatRoomRepository;

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public ChatRoom getOrCreateRoom(long user1Id, long user2Id) {
        if (user1Id == user2Id) {
            throw new IllegalArgumentException("Cannot create a chat room with oneself");
        }

        // Generate deterministic chatId (lower ID first)
        long lowerId = Math.min(user1Id, user2Id);
        long higherId = Math.max(user1Id, user2Id);
        String chatId = lowerId + "_" + higherId;

        Optional<ChatRoom> existingRoom = chatRoomRepository.findByChatId(chatId);
        if (existingRoom.isPresent()) {
            return existingRoom.get();
        }

        User user1 = userRepository.findById(lowerId)
                .orElseThrow(() -> new RuntimeException("User not found: " + lowerId));
        User user2 = userRepository.findById(higherId)
                .orElseThrow(() -> new RuntimeException("User not found: " + higherId));

        ChatRoom newRoom = new ChatRoom();
        newRoom.setChatId(chatId);
        newRoom.setUser1(user1);
        newRoom.setUser2(user2);
        newRoom.setLastMessage("");
        newRoom.setLastMessageTimestamp(LocalDateTime.now());

        return chatRoomRepository.save(newRoom);
    }

    @Transactional
    public ChatMessage saveMessage(long senderId, long recipientId, String content) {
        ChatRoom room = getOrCreateRoom(senderId, recipientId);

        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new RuntimeException("Sender not found: " + senderId));
        User recipient = userRepository.findById(recipientId)
                .orElseThrow(() -> new RuntimeException("Recipient not found: " + recipientId));

        ChatMessage message = new ChatMessage();
        message.setChatRoom(room);
        message.setSender(sender);
        message.setRecipient(recipient);
        message.setContent(content);
        message.setTimestamp(LocalDateTime.now());
        message.setIsRead(false);

        ChatMessage saved = chatMessageRepository.save(message);

        // Update the chat room last message details
        room.setLastMessage(content);
        room.setLastMessageTimestamp(saved.getTimestamp());
        chatRoomRepository.save(room);

        return saved;
    }

    public List<ChatRoom> getRoomsForUser(long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));
        return chatRoomRepository.findAllRoomsForUser(user);
    }

    public List<ChatMessage> getChatHistory(long roomId) {
        ChatRoom room = chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Chat room not found: " + roomId));
        return chatMessageRepository.findByChatRoomOrderByTimestampAsc(room);
    }

    @Transactional
    public void markRoomMessagesAsRead(long roomId, long userId) {
        ChatRoom room = chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Chat room not found: " + roomId));
        chatMessageRepository.markMessagesAsRead(room, userId);
    }
}
