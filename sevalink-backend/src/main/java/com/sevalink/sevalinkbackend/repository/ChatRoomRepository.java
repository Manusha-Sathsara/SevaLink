package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.ChatRoom;
import com.sevalink.sevalinkbackend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {
    Optional<ChatRoom> findByChatId(String chatId);

    @Query("SELECT cr FROM ChatRoom cr WHERE cr.user1 = :user OR cr.user2 = :user ORDER BY cr.lastMessageTimestamp DESC")
    List<ChatRoom> findAllRoomsForUser(@Param("user") User user);
}
