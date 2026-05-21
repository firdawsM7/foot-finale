package com.club.controller;

import com.club.dto.ChatMessageDto;
import com.club.exception.SafeErrorMessages;
import com.club.security.InputSanitizer;
import com.club.model.ChatMessage;
import com.club.model.User;
import com.club.repository.ChatMessageRepository;
import com.club.repository.UserRepository;
import com.club.service.MessageNotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/messages")
public class UserMessageController {

    private static final Logger log = LoggerFactory.getLogger(UserMessageController.class);

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private MessageNotificationService messageNotificationService;

    // Récupérer les annonces générales destinées à l'utilisateur (broadcast + groupe selon son rôle)
    @GetMapping("/announcements")
    public ResponseEntity<List<ChatMessageDto>> getMyAnnouncements(Authentication authentication) {
        try {
            User user = (User) authentication.getPrincipal();
            List<ChatMessage> messages = chatMessageRepository.findAdminMessagesForUserAndRole(user.getId(), user.getRole());

            // Filtrer pour ne garder que les annonces publiques/de groupe (pas les messages privés)
            List<ChatMessageDto> dtos = messages.stream()
                    .filter(m -> m.getRecipientId() == null)
                    .map(ChatMessageDto::fromEntity)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    // Récupérer la conversation privée 1-à-1 exclusive avec l'administrateur
    @GetMapping("/admin-conversation")
    public ResponseEntity<List<ChatMessageDto>> getConversationWithAdmin(Authentication authentication) {
        try {
            User user = (User) authentication.getPrincipal();
            
            // Trouver le premier administrateur du système
            User admin = userRepository.findByRole(User.Role.ADMIN).stream()
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException("Administrateur système introuvable"));

            List<ChatMessage> messages = chatMessageRepository.findPrivateConversationWithAdmin(user.getId(), admin.getId());

            List<ChatMessageDto> dtos = messages.stream()
                    .map(ChatMessageDto::fromEntity)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    // Envoyer un message privé à l'administrateur (réponse)
    @PostMapping("/to-admin")
    public ResponseEntity<?> sendMessageToAdmin(
            @RequestBody Map<String, String> request,
            Authentication authentication) {
        try {
            User sender = (User) authentication.getPrincipal();
            String content = InputSanitizer.sanitizeText(request.get("content"));

            if (content == null || content.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.INVALID_REQUEST));
            }

            // Trouver le premier administrateur du système comme destinataire
            User admin = userRepository.findByRole(User.Role.ADMIN).stream()
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException("Administrateur système introuvable"));

            // Créer le message privé
            ChatMessage message = new ChatMessage();
            message.setContent(content);
            message.setSender(sender);
            message.setTimestamp(LocalDateTime.now());
            message.setType(ChatMessage.MessageType.TEXT);
            message.setTeam(null); // messagerie admin (sans équipe) - NULL is now properly supported
            message.setRecipientId(admin.getId());
            message.setRecipientRole(null);

            ChatMessage saved = chatMessageRepository.save(message);

            // Synchronisation temps réel via WebSocket
            ChatMessageDto dto = ChatMessageDto.fromEntity(saved);
            
            // Notifier le tableau de bord d'administration
            messagingTemplate.convertAndSend("/topic/admin-messages", dto);
            messagingTemplate.convertAndSend("/topic/user-" + sender.getId() + "/messages", dto);
            messageNotificationService.notifyPrivateMessage(dto, sender.getId(), admin.getId());

            return ResponseEntity.ok(Map.of(
                    "message", "Message envoyé à l'administration avec succès",
                    "data", dto
            ));
        } catch (Exception e) {
            log.error("Erreur envoi message utilisateur", e);
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.MESSAGE_SEND_FAILED));
        }
    }
}
