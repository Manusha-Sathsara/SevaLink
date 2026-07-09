package com.sevalink.sevalinkbackend.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class ChatConversationDto {
    private Long partnerId;
    private String partnerName;
    private String partnerProfileImageUrl;
    private String lastMessage;
    private LocalDateTime lastMessageTime;
    private long unreadCount;
    private boolean isOnline;
}
