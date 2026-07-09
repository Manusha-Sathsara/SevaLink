package com.sevalink.sevalinkbackend.service;

import com.sevalink.sevalinkbackend.dto.ChatConversationDto;
import com.sevalink.sevalinkbackend.dto.ChatMessageDto;
import com.sevalink.sevalinkbackend.dto.SendMessageRequest;
import com.sevalink.sevalinkbackend.model.ChatMessage;
import com.sevalink.sevalinkbackend.model.JobPost;
import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.repository.ChatMessageRepository;
import com.sevalink.sevalinkbackend.repository.JobPostRepository;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import com.sevalink.sevalinkbackend.model.Notification;
import com.sevalink.sevalinkbackend.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ChatService {

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JobPostRepository jobPostRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    public ChatMessageDto sendMessage(String senderEmail, SendMessageRequest request) {
        User sender = userRepository.findByEmail(senderEmail)
                .orElseThrow(() -> new RuntimeException("Sender not found"));
        User receiver = userRepository.findById(request.getReceiverId())
                .orElseThrow(() -> new RuntimeException("Receiver not found"));

        ChatMessage message = new ChatMessage();
        message.setSender(sender);
        message.setReceiver(receiver);
        message.setContent(request.getContent());

        if (request.getJobPostId() != null) {
            JobPost jobPost = jobPostRepository.findById(request.getJobPostId())
                    .orElse(null);
            message.setJobPost(jobPost);
        }

        ChatMessage saved = chatMessageRepository.save(message);

        // Notify receiver about new message
        try {
            Notification notification = new Notification();
            notification.setUser(receiver);
            if (message.getJobPost() != null) {
                notification.setJobPost(message.getJobPost());
            }
            notification.setTitle("New Message from " + sender.getFullName());
            notification.setMessage(message.getContent().length() > 60
                    ? message.getContent().substring(0, 57) + "..."
                    : message.getContent());
            notificationRepository.save(notification);
        } catch (Exception e) {
            // Notification failures should not fail the message sending itself
            System.err.println("Failed to create message notification: " + e.getMessage());
        }

        return toDto(saved);
    }

    public List<ChatMessageDto> getConversation(String userEmail, Long otherUserId) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<ChatMessage> messages = chatMessageRepository.findConversation(user.getId(), otherUserId);

        // Mark received messages as read
        messages.stream()
                .filter(m -> m.getReceiver().getId() == user.getId() && !m.getIsRead())
                .forEach(m -> {
                    m.setIsRead(true);
                    chatMessageRepository.save(m);
                });

        return messages.stream().map(this::toDto).collect(Collectors.toList());
    }

    public List<ChatConversationDto> getConversations(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<Long> partnerIds = chatMessageRepository.findConversationPartnerIds(user.getId());
        List<ChatConversationDto> conversations = new ArrayList<>();

        for (Long partnerId : partnerIds) {
            User partner = userRepository.findById(partnerId).orElse(null);
            if (partner == null) continue;

            ChatMessage lastMsg = chatMessageRepository.findLastMessage(user.getId(), partnerId);
            long unread = chatMessageRepository.countUnreadMessages(user.getId(), partnerId);

            conversations.add(ChatConversationDto.builder()
                    .partnerId(partnerId)
                    .partnerName(partner.getFullName())
                    .partnerProfileImageUrl(partner.getProfileImageUrl())
                    .lastMessage(lastMsg != null ? lastMsg.getContent() : "")
                    .lastMessageTime(lastMsg != null ? lastMsg.getCreatedAt() : null)
                    .unreadCount(unread)
                    .isOnline(false)
                    .build());
        }

        // Sort by last message time descending
        conversations.sort((a, b) -> {
            if (a.getLastMessageTime() == null) return 1;
            if (b.getLastMessageTime() == null) return -1;
            return b.getLastMessageTime().compareTo(a.getLastMessageTime());
        });

        return conversations;
    }

    private ChatMessageDto toDto(ChatMessage message) {
        return ChatMessageDto.builder()
                .id(message.getId())
                .senderId(message.getSender().getId())
                .senderName(message.getSender().getFullName())
                .receiverId(message.getReceiver().getId())
                .receiverName(message.getReceiver().getFullName())
                .jobPostId(message.getJobPost() != null ? message.getJobPost().getId() : null)
                .content(message.getContent())
                .isRead(message.getIsRead())
                .createdAt(message.getCreatedAt())
                .build();
    }
}
