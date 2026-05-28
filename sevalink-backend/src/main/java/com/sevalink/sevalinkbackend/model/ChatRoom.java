package com.sevalink.sevalinkbackend.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "chat_rooms", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"chat_id"})
})
@Data
@NoArgsConstructor
@AllArgsConstructor 

public class ChatRoom {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "chat_id", nullable = false, unique = true)
    private String chatId;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "user1_id", nullable = false)
    private User user1;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "user2_id", nullable = false)
    private User user2;

    @Column(length = 1000)
    private String lastMessage;

    private LocalDateTime lastMessageTimestamp;
}

