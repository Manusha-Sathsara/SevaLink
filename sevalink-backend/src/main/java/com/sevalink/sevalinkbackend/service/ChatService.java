package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.ChatRoomResponse;
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
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class ChatService {

    @Autowired
    private ChatRoomRepository chatRoomRepository;

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private UserRepository userRepository;

    public ChatRoom getOrCreateChatRoom(Long userId1, Long userId2) {
        User user1 = userRepository.findById(userId1)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId1));
        User user2 = userRepository.findById(userId2)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId2));

        // Enforce user1Id < user2Id to maintain uniqueness
        User firstUser = user1.getId() < user2.getId() ? user1 : user2;
        User secondUser = user1.getId() < user2.getId() ? user2 : user1;

        Optional<ChatRoom> existingRoom = chatRoomRepository.findByUser1IdAndUser2Id(firstUser.getId(), secondUser.getId());
        if (existingRoom.isPresent()) {
            return existingRoom.get();
        }

        ChatRoom chatRoom = new ChatRoom();
        chatRoom.setUser1(firstUser);
        chatRoom.setUser2(secondUser);
        chatRoom.setCreatedAt(LocalDateTime.now());
        chatRoom.setLastMessageAt(LocalDateTime.now());
        return chatRoomRepository.save(chatRoom);
    }

    public List<ChatRoomResponse> getChatRoomsForUser(Long userId) {
        List<ChatRoom> rooms = chatRoomRepository.findByUser1IdOrUser2IdOrderByLastMessageAtDesc(userId, userId);
        List<ChatRoomResponse> responses = new ArrayList<>();

        for (ChatRoom room : rooms) {
            User otherUser = room.getUser1().getId() == userId ? room.getUser2() : room.getUser1();
            
            Optional<ChatMessage> lastMsgOpt = chatMessageRepository.findFirstByChatRoomIdOrderByTimestampDesc(room.getId());
            String lastMessage = lastMsgOpt.map(ChatMessage::getContent).orElse("No messages yet");
            LocalDateTime lastMessageAt = lastMsgOpt.map(ChatMessage::getTimestamp).orElse(room.getLastMessageAt());
            
            long unreadCount = chatMessageRepository.countByChatRoomIdAndRecipientIdAndIsReadFalse(room.getId(), userId);

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

    public ChatMessage sendMessage(Long chatRoomId, Long senderId, Long recipientId, String content) {
        ChatRoom room = chatRoomRepository.findById(chatRoomId)
                .orElseThrow(() -> new RuntimeException("Chat room not found with id: " + chatRoomId));
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new RuntimeException("Sender not found with id: " + senderId));
        User recipient = userRepository.findById(recipientId)
                .orElseThrow(() -> new RuntimeException("Recipient not found with id: " + recipientId));

        ChatMessage message = new ChatMessage();
        message.setChatRoom(room);
        message.setSender(sender);
        message.setRecipient(recipient);
        message.setContent(content);
        message.setTimestamp(LocalDateTime.now());
        message.setIsRead(false);

        ChatMessage saved = chatMessageRepository.save(message);

        // Update the room's last message time
        room.setLastMessageAt(LocalDateTime.now());
        chatRoomRepository.save(room);

        return saved;
    }

    public List<ChatMessage> getChatMessages(Long chatRoomId, Long currentUserId) {
        // Mark unread messages in this room received by currentUserId as read
        List<ChatMessage> unreadMessages = chatMessageRepository
                .findByChatRoomIdAndRecipientIdAndIsReadFalse(chatRoomId, currentUserId);
        for (ChatMessage msg : unreadMessages) {
            msg.setIsRead(true);
        }
        if (!unreadMessages.isEmpty()) {
            chatMessageRepository.saveAll(unreadMessages);
        }

        return chatMessageRepository.findByChatRoomIdOrderByTimestampAsc(chatRoomId);
    }

    public long getGlobalUnreadCount(Long userId) {
        return chatMessageRepository.countByRecipientIdAndIsReadFalse(userId);
    }
}
