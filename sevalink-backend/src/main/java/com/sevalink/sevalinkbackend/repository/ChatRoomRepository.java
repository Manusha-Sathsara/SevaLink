package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {
    Optional<ChatRoom> findByUser1IdAndUser2Id(Long user1Id, Long user2Id);
    
    List<ChatRoom> findByUser1IdOrUser2IdOrderByLastMessageAtDesc(Long user1Id, Long user2Id);
}
