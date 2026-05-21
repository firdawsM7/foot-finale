package com.club.dto;

import com.club.model.MessageNotification;
import java.time.LocalDateTime;

public class MessageNotificationDto {
    private Long id;
    private String type;
    private String title;
    private String body;
    private Long senderId;
    private String senderName;
    private Long teamId;
    private Long messageId;
    private boolean read;
    private LocalDateTime createdAt;

    public static MessageNotificationDto fromEntity(MessageNotification n) {
        MessageNotificationDto dto = new MessageNotificationDto();
        dto.setId(n.getId());
        dto.setType(n.getType().name());
        dto.setTitle(n.getTitle());
        dto.setBody(n.getBody());
        dto.setSenderId(n.getSenderId());
        dto.setSenderName(n.getSenderName());
        dto.setTeamId(n.getTeamId());
        dto.setMessageId(n.getMessageId());
        dto.setRead(n.isRead());
        dto.setCreatedAt(n.getCreatedAt());
        return dto;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }

    public Long getSenderId() {
        return senderId;
    }

    public void setSenderId(Long senderId) {
        this.senderId = senderId;
    }

    public String getSenderName() {
        return senderName;
    }

    public void setSenderName(String senderName) {
        this.senderName = senderName;
    }

    public Long getTeamId() {
        return teamId;
    }

    public void setTeamId(Long teamId) {
        this.teamId = teamId;
    }

    public Long getMessageId() {
        return messageId;
    }

    public void setMessageId(Long messageId) {
        this.messageId = messageId;
    }

    public boolean isRead() {
        return read;
    }

    public void setRead(boolean read) {
        this.read = read;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
