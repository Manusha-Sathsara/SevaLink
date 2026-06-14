package com.sevalink.sevalinkbackend.config;

import com.sevalink.sevalinkbackend.websocket.WebSocketAuthChannelInterceptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * Configures the STOMP WebSocket message broker for real-time chat.
 *
 * Connection flow:
 *  1. Flutter client connects to ws://host:8080/ws-chat (SockJS fallback supported)
 *  2. Client sends JWT in STOMP CONNECT headers (Authorization: Bearer <token>)
 *  3. Client subscribes to /topic/messages/{roomId}
 *  4. Client sends messages to /app/chat.send  (handled by ChatWebSocketController)
 *  5. Backend broadcasts to /topic/messages/{roomId} after DB persist
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Autowired
    private WebSocketAuthChannelInterceptor webSocketAuthChannelInterceptor;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // Prefix for topics that clients subscribe to (e.g. /topic/messages/42)
        registry.enableSimpleBroker("/topic");

        // Prefix for messages routed to @MessageMapping methods in controllers
        registry.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry
            .addEndpoint("/ws-chat")
            // Accept connections from Flutter mobile, web, and local dev
            .setAllowedOriginPatterns("*")
            // Enable SockJS fallback for environments that block raw WebSocket
            .withSockJS();
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        // Attach JWT auth interceptor to every inbound STOMP frame
        registration.interceptors(webSocketAuthChannelInterceptor);
    }
}
