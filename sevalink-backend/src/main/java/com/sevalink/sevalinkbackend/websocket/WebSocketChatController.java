package com.sevalink.sevalinkbackend.websocket;

import com.sevalink.sevalinkbackend.dto.ChatDTOs.*;
import com.sevalink.sevalinkbackend.service.MessageService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class WebSocketChatController {

    private final MessageService messageService;

    @MessageMapping("/chat.send")
    public void handleMessage(@Payload SendMessageRequest request) {
        messageService.sendMessage(request);
    }

    @MessageMapping("/chat.read")
    public void handleReadReceipt(@Payload MarkReadRequest request) {
        messageService.markMessagesAsRead(
                request.getConversationId(),
                request.getReceiverId()
        );
    }
}