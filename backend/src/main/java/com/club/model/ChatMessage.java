package com.club.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "chat_messages")
public class ChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String content;

    @ManyToOne
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    // Optional relationship to team - can be null for admin messages
    @ManyToOne(optional = true)
    @JoinColumn(name = "equipe_id", nullable = true, foreignKey = @ForeignKey(name = "FK_chat_messages_equipe"))
    private Equipe team;

    // Optional: private message to a specific user (still belongs to a team context)
    @Column(nullable = true)
    private Long recipientId;

    @Enumerated(EnumType.STRING)
    @Column(name = "recipient_role", nullable = true)
    private User.Role recipientRole;

    // Optional attachment
    @Column(nullable = true)
    private String attachmentUrl;
    @Column(nullable = true)
    private String attachmentName;
    @Column(nullable = true)
    private String attachmentContentType;
    @Column(nullable = true)
    private Long attachmentSize;

    @Column(nullable = false)
    private LocalDateTime timestamp;

    @Convert(converter = MessageTypeConverter.class)
    @Column(nullable = false)
    private MessageType type = MessageType.TEXT;

    @Column(nullable = false)
    private boolean deleted = false;

    public ChatMessage() {
    }

    public ChatMessage(String content, User sender, Equipe team, LocalDateTime timestamp, MessageType type) {
        this.content = content;
        this.sender = sender;
        this.team = team;
        this.timestamp = timestamp;
        this.type = type;
    }

    // Legacy constructor for backward compatibility
    public ChatMessage(String content, User sender, Long teamId, LocalDateTime timestamp, MessageType type) {
        this.content = content;
        this.sender = sender;
        this.timestamp = timestamp;
        this.type = type;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public User getSender() {
        return sender;
    }

    public void setSender(User sender) {
        this.sender = sender;
    }

    public Long getTeamId() {
        return team != null ? team.getId() : null;
    }

    public void setTeamId(Long teamId) {
        // Legacy method - kept for backward compatibility
        // This will be removed in future versions
        if (teamId != null) {
            Equipe equipe = new Equipe();
            equipe.setId(teamId);
            this.team = equipe;
        } else {
            this.team = null;
        }
    }

    public Equipe getTeam() {
        return team;
    }

    public void setTeam(Equipe team) {
        this.team = team;
    }

    public Long getRecipientId() {
        return recipientId;
    }

    public void setRecipientId(Long recipientId) {
        this.recipientId = recipientId;
    }

    public User.Role getRecipientRole() {
        return recipientRole;
    }

    public void setRecipientRole(User.Role recipientRole) {
        this.recipientRole = recipientRole;
    }

    public String getAttachmentUrl() {
        return attachmentUrl;
    }

    public void setAttachmentUrl(String attachmentUrl) {
        this.attachmentUrl = attachmentUrl;
    }

    public String getAttachmentName() {
        return attachmentName;
    }

    public void setAttachmentName(String attachmentName) {
        this.attachmentName = attachmentName;
    }

    public String getAttachmentContentType() {
        return attachmentContentType;
    }

    public void setAttachmentContentType(String attachmentContentType) {
        this.attachmentContentType = attachmentContentType;
    }

    public Long getAttachmentSize() {
        return attachmentSize;
    }

    public void setAttachmentSize(Long attachmentSize) {
        this.attachmentSize = attachmentSize;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    public MessageType getType() {
        return type;
    }

    public void setType(MessageType type) {
        this.type = type;
    }

    public boolean isDeleted() {
        return deleted;
    }

    public void setDeleted(boolean deleted) {
        this.deleted = deleted;
    }

    public enum MessageType {
        TEXT,
        FILE,
        SYSTEM
    }
}
