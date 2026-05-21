package com.club.controller;

import com.club.dto.ChatMessageDto;
import com.club.model.ChatMessage;
import com.club.model.Equipe;
import com.club.model.User;
import com.club.repository.ChatMessageRepository;
import com.club.repository.EquipeRepository;
import com.club.repository.UserRepository;
import com.club.security.InputSanitizer;
import com.club.security.SecureFileValidator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@RestController
public class ChatController {

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EquipeRepository equipeRepository;

    @MessageMapping("/chat.sendMessage")
    public void sendMessage(@Payload ChatMessageDto chatMessageDto) {
        User sender = userRepository.findById(chatMessageDto.getSenderId())
                .orElseThrow(() -> new RuntimeException("User not found"));

        Long teamId = resolveTeamId(chatMessageDto);

        ChatMessage chatMessage = new ChatMessage();
        chatMessage.setContent(InputSanitizer.sanitizeText(chatMessageDto.getContent()));
        chatMessage.setSender(sender);
        chatMessage.setTimestamp(LocalDateTime.now());
        chatMessage.setType(ChatMessage.MessageType.TEXT);
        
        // Properly set the team relationship
        if (teamId != null) {
            Equipe equipe = equipeRepository.findById(teamId)
                    .orElseThrow(() -> new RuntimeException("Équipe introuvable: " + teamId));
            chatMessage.setTeam(equipe);
        } else {
            chatMessage.setTeam(null);
        }

        chatMessage.setRecipientId(chatMessageDto.getRecipientId());
        chatMessage.setAttachmentUrl(chatMessageDto.getAttachmentUrl());
        chatMessage.setAttachmentName(chatMessageDto.getAttachmentName());
        chatMessage.setAttachmentContentType(chatMessageDto.getAttachmentContentType());
        chatMessage.setAttachmentSize(chatMessageDto.getAttachmentSize());

        chatMessageRepository.save(chatMessage);

        // Update DTO with server timestamp and sender name
        chatMessageDto.setTimestamp(chatMessage.getTimestamp());
        chatMessageDto.setSenderName(sender.getPrenom() + " " + sender.getNom());

        // Private message: deliver only to recipient + sender.
        if (chatMessageDto.getRecipientId() != null) {
            messagingTemplate.convertAndSend("/topic/user/" + chatMessageDto.getRecipientId(), chatMessageDto);
            messagingTemplate.convertAndSend("/topic/user/" + chatMessageDto.getSenderId(), chatMessageDto);
        } else {
            messagingTemplate.convertAndSend("/topic/team/" + teamId, chatMessageDto);
        }
    }

    private Long resolveTeamId(ChatMessageDto dto) {
        Long raw = dto.getTeamId();
        if (dto.getRecipientId() != null) {
            if (raw == null || raw <= 0) {
                return null;
            }
            if (!equipeRepository.existsById(raw)) {
                throw new IllegalArgumentException("Équipe introuvable: " + raw);
            }
            return raw;
        }
        if (raw == null || raw <= 0) {
            throw new IllegalArgumentException("teamId requis pour le chat d'équipe");
        }
        if (!equipeRepository.existsById(raw)) {
            throw new IllegalArgumentException("Équipe introuvable: " + raw);
        }
        return raw;
    }

    @MessageMapping("/chat.addUser")
    public void addUser(@Payload ChatMessageDto chatMessageDto, SimpMessageHeaderAccessor headerAccessor) {
        // Add username in web socket session
        if (headerAccessor.getSessionAttributes() != null) {
            headerAccessor.getSessionAttributes().put("username", chatMessageDto.getSenderName());
        }

        // We could broadcast join message here if needed
        chatMessageDto.setType(ChatMessage.MessageType.SYSTEM);
        chatMessageDto.setTimestamp(LocalDateTime.now());
        messagingTemplate.convertAndSend("/topic/team/" + chatMessageDto.getTeamId(), chatMessageDto);
    }

    @GetMapping("/chat/history/{teamId}")
    public List<ChatMessageDto> getChatHistory(@PathVariable Long teamId) {
        return chatMessageRepository.findByTeam_IdOrderByTimestampAsc(teamId).stream()
                .map(msg -> {
                    ChatMessageDto dto = new ChatMessageDto();
                    dto.setContent(msg.getContent());
                    dto.setSenderId(msg.getSender().getId());
                    dto.setSenderName(msg.getSender().getPrenom() + " " + msg.getSender().getNom());
                    dto.setTeamId(msg.getTeamId());
                    dto.setRecipientId(msg.getRecipientId());
                    dto.setTimestamp(msg.getTimestamp());
                    if (msg.getType() != null) {
                        dto.setType(msg.getType());
                    }
                    dto.setAttachmentUrl(msg.getAttachmentUrl());
                    dto.setAttachmentName(msg.getAttachmentName());
                    dto.setAttachmentContentType(msg.getAttachmentContentType());
                    dto.setAttachmentSize(msg.getAttachmentSize());
                    return dto;
                })
                .collect(Collectors.toList());
    }

    @PostMapping("/chat/attachments")
    public ResponseEntity<?> uploadChatAttachment(
            @RequestParam("teamId") Long teamId,
            @RequestParam("file") MultipartFile file) throws IOException {
        try {
            SecureFileValidator.validateImageUpload(file, 5L * 1024 * 1024);
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(Map.of("error", com.club.exception.SafeErrorMessages.INVALID_REQUEST));
        }

        String baseDir = System.getProperty("user.dir");
        Path uploadDir = Paths.get(baseDir, "uploads", "chat", teamId.toString()).toAbsolutePath().normalize();
        Files.createDirectories(uploadDir);

        String ext = SecureFileValidator.extension(file.getOriginalFilename());
        String fileName = SecureFileValidator.safeStoredFileName(ext);
        Path target = uploadDir.resolve(fileName);
        if (!target.normalize().startsWith(uploadDir)) {
            return ResponseEntity.badRequest().body(Map.of("error", com.club.exception.SafeErrorMessages.INVALID_REQUEST));
        }
        file.transferTo(target.toFile());

        String fileUrl = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path("/uploads/chat/")
                .path(teamId.toString())
                .path("/")
                .path(fileName)
                .toUriString();

        Map<String, Object> out = new HashMap<>();
        out.put("url", fileUrl);
        out.put("fileName", fileName);
        out.put("originalName", file.getOriginalFilename());
        out.put("contentType", file.getContentType());
        out.put("size", file.getSize());
        return ResponseEntity.ok(out);
    }
}
