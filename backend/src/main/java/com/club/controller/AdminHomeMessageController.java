package com.club.controller;

import com.club.dto.ChatMessageDto;
import com.club.exception.SafeErrorMessages;
import com.club.security.InputSanitizer;
import com.club.model.ChatMessage;
import com.club.model.User;
import com.club.repository.ChatMessageRepository;
import com.club.service.UserService;
import com.club.service.MessageNotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Exposes the exact same messaging API as {@link AdminMessageController} but under the
 * "/admin/home/messages" base path. This allows the admin home page UI to reuse the
 * existing messaging component without duplication.
 */
@RestController
@RequestMapping("/admin/home/messages")
@PreAuthorize("hasRole('ADMIN')")
public class AdminHomeMessageController {

    private static final Logger log = LoggerFactory.getLogger(AdminHomeMessageController.class);

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private UserService userService;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private MessageNotificationService messageNotificationService;

    // Broadcast to all users (same logic as AdminMessageController)
    @PostMapping("/broadcast")
    public ResponseEntity<?> broadcastMessage(@RequestBody Map<String, Object> request,
                                             Authentication authentication) {
        try {
            User sender = (User) authentication.getPrincipal();
            String content = InputSanitizer.sanitizeText((String) request.get("content"));
            if (content == null || content.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.INVALID_REQUEST));
            }
            ChatMessage message = new ChatMessage();
            message.setContent(content);
            message.setSender(sender);
            message.setTimestamp(LocalDateTime.now());
            message.setType(ChatMessage.MessageType.TEXT);
            message.setTeamId(null);
            message.setRecipientId(null);
            message.setRecipientRole(null);
            ChatMessage saved = chatMessageRepository.save(message);
            ChatMessageDto dto = ChatMessageDto.fromEntity(saved);
            messagingTemplate.convertAndSend("/topic/admin-messages", dto);
            messagingTemplate.convertAndSend("/topic/broadcast/messages", dto);
            messageNotificationService.notifyBroadcast(dto, sender.getId());
            return ResponseEntity.ok(Map.of("message", "Message broadcast envoyé avec succès", "data", dto));
        } catch (Exception e) {
            log.error("Erreur envoi message", e);
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.MESSAGE_SEND_FAILED));
        }
    }

    // Group message by role (same logic as AdminMessageController)
    @PostMapping("/group/{roleStr}")
    public ResponseEntity<?> sendGroupMessage(@PathVariable String roleStr,
                                             @RequestBody Map<String, String> request,
                                             Authentication authentication) {
        try {
            User sender = (User) authentication.getPrincipal();
            String content = InputSanitizer.sanitizeText(request.get("content"));
            if (content == null || content.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.INVALID_REQUEST));
            }
            User.Role role;
            try {
                role = User.Role.valueOf(roleStr.toUpperCase());
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.INVALID_REQUEST));
            }
            ChatMessage message = new ChatMessage();
            message.setContent(content);
            message.setSender(sender);
            message.setTimestamp(LocalDateTime.now());
            message.setType(ChatMessage.MessageType.TEXT);
            message.setTeamId(null);
            message.setRecipientId(null);
            message.setRecipientRole(role);
            ChatMessage saved = chatMessageRepository.save(message);
            ChatMessageDto dto = ChatMessageDto.fromEntity(saved);
            messagingTemplate.convertAndSend("/topic/admin-messages", dto);
            messagingTemplate.convertAndSend("/topic/role-" + role.name() + "/messages", dto);
            messageNotificationService.notifyGroupMessage(dto, role, sender.getId());
            return ResponseEntity.ok(Map.of("message", "Message de groupe envoyé avec succès", "data", dto));
        } catch (Exception e) {
            log.error("Erreur envoi message", e);
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.MESSAGE_SEND_FAILED));
        }
    }

    // Private message to a specific user (same logic as AdminMessageController)
    @PostMapping("/private/{userId}")
    public ResponseEntity<?> sendPrivateMessage(@PathVariable Long userId,
                                                @RequestBody Map<String, String> request,
                                                Authentication authentication) {
        try {
            User sender = (User) authentication.getPrincipal();
            String content = InputSanitizer.sanitizeText(request.get("content"));
            if (content == null || content.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.INVALID_REQUEST));
            }
            User recipient = userService.getUserById(userId);
            ChatMessage message = new ChatMessage();
            message.setContent(content);
            message.setSender(sender);
            message.setTimestamp(LocalDateTime.now());
            message.setType(ChatMessage.MessageType.TEXT);
            message.setTeamId(null);
            message.setRecipientId(userId);
            message.setRecipientRole(null);
            ChatMessage saved = chatMessageRepository.save(message);
            ChatMessageDto dto = ChatMessageDto.fromEntity(saved);
            messagingTemplate.convertAndSend("/topic/admin-messages", dto);
            messagingTemplate.convertAndSend("/topic/user-" + userId + "/messages", dto);
            messageNotificationService.notifyPrivateMessage(dto, sender.getId(), userId);
            return ResponseEntity.ok(Map.of("message", "Message privé envoyé avec succès", "data", dto));
        } catch (Exception e) {
            log.error("Erreur envoi message", e);
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.MESSAGE_SEND_FAILED));
        }
    }

    // Retrieve all admin messages (broadcast + privés)
    @GetMapping
    public ResponseEntity<List<ChatMessageDto>> getAllAdminMessages() {
        List<ChatMessage> messages = chatMessageRepository.findAllAdminMessages();
        List<ChatMessageDto> dtos = messages.stream().map(ChatMessageDto::fromEntity).collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    // Retrieve messages for a specific user
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<ChatMessageDto>> getMessagesForUser(@PathVariable Long userId) {
        User user = userService.getUserById(userId);
        List<ChatMessage> messages = chatMessageRepository.findAdminMessagesForUserAndRole(userId, user.getRole());
        List<ChatMessageDto> dtos = messages.stream().map(ChatMessageDto::fromEntity).collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    // Private conversation between admin and a user
    @GetMapping("/private-conversation/{userId}")
    public ResponseEntity<List<ChatMessageDto>> getPrivateConversation(@PathVariable Long userId,
                                                                      Authentication authentication) {
        User admin = (User) authentication.getPrincipal();
        List<ChatMessage> messages = chatMessageRepository.findPrivateConversationWithAdmin(userId, admin.getId());
        List<ChatMessageDto> dtos = messages.stream().map(ChatMessageDto::fromEntity).collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }
}
