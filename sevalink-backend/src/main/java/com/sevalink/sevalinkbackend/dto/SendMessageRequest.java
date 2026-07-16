package com.sevalink.sevalinkbackend.dto;

import lombok.Data;

@Data
public class SendMessageRequest {
    private Long receiverId;
    private Long jobPostId;
    private String content;
}
