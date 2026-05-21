package com.club.controller;

import com.club.dto.MessageNotificationDto;
import com.club.model.MessageNotification;
import com.club.model.User;
import com.club.repository.MessageNotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/notifications")
public class MessageNotificationController {

    @Autowired
    private MessageNotificationRepository notificationRepository;

    @GetMapping
    public ResponseEntity<List<MessageNotificationDto>> getMyNotifications(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        List<MessageNotificationDto> dtos = notificationRepository.findByUserOrderByCreatedAtDesc(user)
                .stream()
                .limit(50)
                .map(MessageNotificationDto::fromEntity)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/unread-count")
    public ResponseEntity<Map<String, Long>> getUnreadCount(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        long count = notificationRepository.countByUserAndIsReadFalse(user);
        return ResponseEntity.ok(Map.of("count", count));
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(@PathVariable Long id, Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return notificationRepository.findById(id)
                .filter(n -> n.getUser().getId().equals(user.getId()))
                .map(n -> {
                    n.setRead(true);
                    notificationRepository.save(n);
                    return ResponseEntity.ok(Map.of("message", "Notification lue"));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/read-all")
    @Transactional
    public ResponseEntity<?> markAllAsRead(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        notificationRepository.markAllReadForUser(user.getId());
        return ResponseEntity.ok(Map.of("message", "Toutes les notifications sont lues"));
    }
}
