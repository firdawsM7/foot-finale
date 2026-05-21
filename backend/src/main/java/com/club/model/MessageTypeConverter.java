package com.club.model;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class MessageTypeConverter implements AttributeConverter<ChatMessage.MessageType, String> {

    @Override
    public String convertToDatabaseColumn(ChatMessage.MessageType attribute) {
        return attribute == null ? ChatMessage.MessageType.TEXT.name() : attribute.name();
    }

    @Override
    public ChatMessage.MessageType convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isBlank()) {
            return ChatMessage.MessageType.TEXT;
        }
        try {
            return ChatMessage.MessageType.valueOf(dbData);
        } catch (IllegalArgumentException ex) {
            return switch (dbData.toUpperCase()) {
                case "CHAT" -> ChatMessage.MessageType.TEXT;
                case "JOIN", "LEAVE" -> ChatMessage.MessageType.SYSTEM;
                default -> ChatMessage.MessageType.TEXT;
            };
        }
    }
}
