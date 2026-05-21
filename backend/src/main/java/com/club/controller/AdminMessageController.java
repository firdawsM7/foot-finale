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

@RestController
@RequestMapping("/admin/messages")
@PreAuthorize("hasRole('ADMIN')")
public class AdminMessageController {

    private static final Logger log = LoggerFactory.getLogger(AdminMessageController.class);

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private UserService userService;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private MessageNotificationService messageNotificationService;

    // Envoyer un message à TOUS les utilisateurs (broadcast)
    @PostMapping("/broadcast")
    public ResponseEntity<?> broadcastMessage(
            @RequestBody Map<String, Object> request,
            Authentication authentication) {
        try {
            User sender = (User) authentication.getPrincipal();
            String content = InputSanitizer.sanitizeText((String) request.get("content"));

            if (content == null || content.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.INVALID_REQUEST));
            }

            // Créer le message
            ChatMessage message = new ChatMessage();
            message.setContent(content);
            message.setSender(sender);
            message.setTimestamp(LocalDateTime.now());
            message.setType(ChatMessage.MessageType.TEXT);
            message.setTeamId(null); // 0 = message système/admin
            message.setRecipientId(null);
            message.setRecipientRole(null);

            ChatMessage saved = chatMessageRepository.save(message);

            // Envoyer via WebSocket pour notification en temps réel
            ChatMessageDto dto = ChatMessageDto.fromEntity(saved);
            messagingTemplate.convertAndSend("/topic/admin-messages", dto);
            messagingTemplate.convertAndSend("/topic/broadcast/messages", dto);
            messageNotificationService.notifyBroadcast(dto, sender.getId());

            return ResponseEntity.ok(Map.of(
                "message", "Message broadcast envoyé avec succès",
                "data", dto
            ));
        } catch (Exception e) {
            log.error("Erreur envoi message admin", e);
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.MESSAGE_SEND_FAILED));
        }
    }

    // Envoyer un message GROUPÉ par rôle (encadrant, joueur, adhérent...)
    @PostMapping("/group/{roleStr}")
    public ResponseEntity<?> sendGroupMessage(
            @PathVariable String roleStr,
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

            // Créer le message
            ChatMessage message = new ChatMessage();
            message.setContent(content);
            message.setSender(sender);
            message.setTimestamp(LocalDateTime.now());
            message.setType(ChatMessage.MessageType.TEXT);
            message.setTeamId(null);
            message.setRecipientId(null);
            message.setRecipientRole(role);

            ChatMessage saved = chatMessageRepository.save(message);

            // Envoyer via WebSocket
            ChatMessageDto dto = ChatMessageDto.fromEntity(saved);
            messagingTemplate.convertAndSend("/topic/admin-messages", dto);
            messagingTemplate.convertAndSend("/topic/role-" + role.name() + "/messages", dto);

            return ResponseEntity.ok(Map.of(
                "message", "Message de groupe envoyé avec succès",
                "data", dto
            ));
        } catch (Exception e) {
            log.error("Erreur envoi message admin", e);
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.MESSAGE_SEND_FAILED));
        }
    }

    // Envoyer un message PRIVÉ à un utilisateur spécifique
    @PostMapping("/private/{userId}")
    public ResponseEntity<?> sendPrivateMessage(
            @PathVariable Long userId,
            @RequestBody Map<String, String> request,
            Authentication authentication) {
        try {
            User sender = (User) authentication.getPrincipal();
            String content = InputSanitizer.sanitizeText(request.get("content"));

            if (content == null || content.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.INVALID_REQUEST));
            }

            // Vérifier que le destinataire existe
            User recipient = userService.getUserById(userId);

            // Créer le message
            ChatMessage message = new ChatMessage();
            message.setContent(content);
            message.setSender(sender);
            message.setTimestamp(LocalDateTime.now());
            message.setType(ChatMessage.MessageType.TEXT);
            message.setTeamId(null);
            message.setRecipientId(userId);
            message.setRecipientRole(null);

            ChatMessage saved = chatMessageRepository.save(message);

            // Envoyer via WebSocket au destinataire et à l'admin
            ChatMessageDto dto = ChatMessageDto.fromEntity(saved);
            messagingTemplate.convertAndSend("/topic/admin-messages", dto);
            messagingTemplate.convertAndSend("/topic/user-" + userId + "/messages", dto);
            messageNotificationService.notifyPrivateMessage(dto, sender.getId(), userId);

            return ResponseEntity.ok(Map.of(
                "message", "Message privé envoyé avec succès",
                "data", dto
            ));
        } catch (Exception e) {
            log.error("Erreur envoi message admin", e);
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.MESSAGE_SEND_FAILED));
        }
    }

    // Récupérer TOUS les messages admin (broadcast + privés)
    @GetMapping
    public ResponseEntity<List<ChatMessageDto>> getAllAdminMessages() {
        List<ChatMessage> messages = chatMessageRepository.findAllAdminMessages();
        
        List<ChatMessageDto> dtos = messages.stream()
            .map(ChatMessageDto::fromEntity)
            .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    // Récupérer les messages pour un utilisateur spécifique
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<ChatMessageDto>> getMessagesForUser(@PathVariable Long userId) {
        User user = userService.getUserById(userId);
        List<ChatMessage> messages = chatMessageRepository.findAdminMessagesForUserAndRole(userId, user.getRole());
        
        List<ChatMessageDto> dtos = messages.stream()
            .map(ChatMessageDto::fromEntity)
            .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    // Récupérer la discussion privée 1-à-1 exclusive avec un utilisateur
    @GetMapping("/private-conversation/{userId}")
    public ResponseEntity<List<ChatMessageDto>> getPrivateConversation(@PathVariable Long userId, Authentication authentication) {
        User admin = (User) authentication.getPrincipal();
        List<ChatMessage> messages = chatMessageRepository.findPrivateConversationWithAdmin(userId, admin.getId());
        
        List<ChatMessageDto> dtos = messages.stream()
            .map(ChatMessageDto::fromEntity)
            .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    // Récupérer l'historique des messages envoyés par l'admin
    @GetMapping("/sent")
    public ResponseEntity<List<ChatMessageDto>> getSentMessages(Authentication authentication) {
        User admin = (User) authentication.getPrincipal();
        
        List<ChatMessage> messages = chatMessageRepository.findBySenderOrderByTimestampDesc(admin);
        
        List<ChatMessageDto> dtos = messages.stream()
            .filter(m -> m.getTeamId() == null) // Seulement les messages admin
            .map(ChatMessageDto::fromEntity)
            .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    // Statistiques des messages
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getMessageStats() {
        List<ChatMessage> allAdminMessages = chatMessageRepository.findAllAdminMessages();
        
        long totalMessages = allAdminMessages.size();
        long broadcastMessages = allAdminMessages.stream().filter(m -> m.getRecipientId() == null).count();
        long privateMessages = allAdminMessages.stream().filter(m -> m.getRecipientId() != null).count();

        return ResponseEntity.ok(Map.of(
            "totalMessages", totalMessages,
            "broadcastMessages", broadcastMessages,
            "privateMessages", privateMessages
        ));
    }
}
