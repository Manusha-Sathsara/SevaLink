package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.model.Notification;
import com.sevalink.sevalinkbackend.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = "*")
public class NotificationController {

    @Autowired
    private NotificationRepository notificationRepository;

    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getUserNotifications(@PathVariable Long userId) {
        List<Notification> notifications = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
        long unreadCount = notificationRepository.countByUserIdAndIsReadFalse(userId);
        
        Map<String, Object> response = new HashMap<>();
        response.put("notifications", notifications);
        response.put("unreadCount", unreadCount);
        
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(@PathVariable Long id) {
        return notificationRepository.findById(id).map(notification -> {
            notification.setIsRead(true);
            Notification saved = notificationRepository.save(notification);
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @Transactional
    @PutMapping("/user/{userId}/read-all")
    public ResponseEntity<?> markAllAsRead(@PathVariable Long userId) {
        List<Notification> notifications = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
        for (Notification notification : notifications) {
            notification.setIsRead(true);
        }
        notificationRepository.saveAll(notifications);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("unreadCount", 0);
        return ResponseEntity.ok(response);
    }

    @Transactional
    @DeleteMapping("/user/{userId}/clear-all")
    public ResponseEntity<?> clearAllNotifications(@PathVariable Long userId) {
        List<Notification> notifications = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
        notificationRepository.deleteAll(notifications);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("unreadCount", 0);
        return ResponseEntity.ok(response);
    }
}

