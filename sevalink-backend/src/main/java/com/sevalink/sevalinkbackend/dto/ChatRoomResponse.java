package com.sevalink.sevalinkbackend.dto;

import com.sevalink.sevalinkbackend.model.UserRole;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChatRoomResponse {
    private Long id;
    private Long otherUserId;
    private String otherUserFullName;
    private UserRole otherUserRole;
    private String lastMessage;
    private LocalDateTime lastMessageAt;
    private long unreadCount;
}
