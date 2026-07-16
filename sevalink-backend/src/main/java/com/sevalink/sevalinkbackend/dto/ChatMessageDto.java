package com.sevalink.sevalinkbackend.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class ChatMessageDto {
    private Long id;
    private Long senderId;
    private String senderName;
    private Long receiverId;
    private String receiverName;
    private Long jobPostId;
    private String content;
    private Boolean isRead;
    private LocalDateTime createdAt;
}
