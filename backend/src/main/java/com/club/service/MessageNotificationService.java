package com.club.service;

import com.club.dto.ChatMessageDto;
import com.club.dto.MessageNotificationDto;
import com.club.model.MessageNotification;
import com.club.model.User;
import com.club.repository.MessageNotificationRepository;
import com.club.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class MessageNotificationService {

    @Autowired
    private MessageNotificationRepository notificationRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Transactional
    public void notifyTeamMessage(ChatMessageDto dto, Long senderId) {
        if (dto.getTeamId() == null) {
            return;
        }
        String senderName = dto.getSenderName() != null ? dto.getSenderName() : "Un membre";
        String preview = truncate(dto.getContent());
        Set<Long> recipientIds = new HashSet<>();

        userRepository.findByEquipeId(dto.getTeamId()).forEach(u -> recipientIds.add(u.getId()));
        userRepository.findByRole(User.Role.ADMIN).forEach(u -> recipientIds.add(u.getId()));
        userRepository.findByRole(User.Role.ENCADRANT).forEach(u -> recipientIds.add(u.getId()));

        recipientIds.remove(senderId);
        for (Long userId : recipientIds) {
            createAndPush(
                    userId,
                    MessageNotification.NotificationType.TEAM,
                    "Nouveau message d'équipe",
                    senderName + " : " + preview,
                    senderId,
                    senderName,
                    dto.getTeamId(),
                    dto.getId()
            );
        }
    }

    @Transactional
    public void notifyPrivateMessage(ChatMessageDto dto, Long senderId, Long recipientId) {
        String senderName = dto.getSenderName() != null ? dto.getSenderName() : "Un utilisateur";
        String preview = truncate(dto.getContent());

        if (recipientId != null && !recipientId.equals(senderId)) {
            createAndPush(
                    recipientId,
                    MessageNotification.NotificationType.PRIVATE,
                    "Nouveau message privé",
                    senderName + " : " + preview,
                    senderId,
                    senderName,
                    null,
                    dto.getId()
            );
        }

        userRepository.findByRole(User.Role.ADMIN).forEach(admin -> {
            if (!admin.getId().equals(senderId) && !admin.getId().equals(recipientId)) {
                createAndPush(
                        admin.getId(),
                        MessageNotification.NotificationType.PRIVATE,
                        "Message privé utilisateur",
                        senderName + " : " + preview,
                        senderId,
                        senderName,
                        null,
                        dto.getId()
                );
            }
        });
    }

    @Transactional
    public void notifyBroadcast(ChatMessageDto dto, Long senderId) {
        String senderName = dto.getSenderName() != null ? dto.getSenderName() : "Administration";
        String preview = truncate(dto.getContent());

        userRepository.findByActif(true).forEach(user -> {
            if (!user.getId().equals(senderId)) {
                createAndPush(
                        user.getId(),
                        MessageNotification.NotificationType.BROADCAST,
                        "Annonce du club",
                        senderName + " : " + preview,
                        senderId,
                        senderName,
                        null,
                        dto.getId()
                );
            }
        });
    }

    @Transactional
    public void notifyGroupMessage(ChatMessageDto dto, User.Role targetRole, Long senderId) {
        String senderName = dto.getSenderName() != null ? dto.getSenderName() : "Administration";
        String preview = truncate(dto.getContent());

        userRepository.findByRole(targetRole).forEach(user -> {
            if (user.getActif() != null && user.getActif() && !user.getId().equals(senderId)) {
                createAndPush(
                        user.getId(),
                        MessageNotification.NotificationType.GROUP,
                        "Message pour " + targetRole.name(),
                        senderName + " : " + preview,
                        senderId,
                        senderName,
                        null,
                        dto.getId()
                );
            }
        });
    }

    private void createAndPush(
            Long userId,
            MessageNotification.NotificationType type,
            String title,
            String body,
            Long senderId,
            String senderName,
            Long teamId,
            Long messageId
    ) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) {
            return;
        }

        MessageNotification notification = new MessageNotification();
        notification.setUser(user);
        notification.setType(type);
        notification.setTitle(title);
        notification.setBody(body);
        notification.setSenderId(senderId);
        notification.setSenderName(senderName);
        notification.setTeamId(teamId);
        notification.setMessageId(messageId);
        notification.setRead(false);
        notification.setCreatedAt(LocalDateTime.now());

        MessageNotification saved = notificationRepository.save(notification);
        MessageNotificationDto dto = MessageNotificationDto.fromEntity(saved);
        messagingTemplate.convertAndSend("/topic/notifications/" + userId, dto);
    }

    private String truncate(String content) {
        if (content == null) {
            return "";
        }
        String trimmed = content.trim();
        return trimmed.length() > 80 ? trimmed.substring(0, 77) + "..." : trimmed;
    }
}
