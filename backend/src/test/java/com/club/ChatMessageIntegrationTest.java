package com.club;

import com.club.model.ChatMessage;
import com.club.model.User;
import com.club.repository.ChatMessageRepository;
import com.club.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class ChatMessageIntegrationTest {

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private UserRepository userRepository;

    @Test
    void savePrivateMessage_persistsDeletedFalse() {
        User admin = userRepository.findByEmail("admin@club.com").orElseThrow();
        User recipient = userRepository.findById(2L).orElseThrow();

        ChatMessage message = new ChatMessage();
        message.setContent("JUnit integration test");
        message.setSender(admin);
        message.setTimestamp(LocalDateTime.now());
        message.setType(ChatMessage.MessageType.TEXT);
        message.setTeamId(null);
        message.setRecipientId(recipient.getId());

        ChatMessage saved = chatMessageRepository.save(message);
        assertNotNull(saved.getId());
        assertFalse(saved.isDeleted());

        chatMessageRepository.deleteById(saved.getId());
    }

    @Test
    void saveBroadcastMessage_persistsDeletedFalse() {
        User admin = userRepository.findByEmail("admin@club.com").orElseThrow();

        ChatMessage message = new ChatMessage();
        message.setContent("JUnit broadcast test");
        message.setSender(admin);
        message.setTimestamp(LocalDateTime.now());
        message.setType(ChatMessage.MessageType.TEXT);
        message.setTeamId(null);

        ChatMessage saved = chatMessageRepository.save(message);
        assertNotNull(saved.getId());
        assertFalse(saved.isDeleted());

        chatMessageRepository.deleteById(saved.getId());
    }

    @Test
    void saveGroupMessage_persistsDeletedFalse() {
        User admin = userRepository.findByEmail("admin@club.com").orElseThrow();

        ChatMessage message = new ChatMessage();
        message.setContent("JUnit group test");
        message.setSender(admin);
        message.setTimestamp(LocalDateTime.now());
        message.setType(ChatMessage.MessageType.TEXT);
        message.setTeamId(null);
        message.setRecipientRole(User.Role.ENCADRANT);

        ChatMessage saved = chatMessageRepository.save(message);
        assertNotNull(saved.getId());
        assertFalse(saved.isDeleted());

        chatMessageRepository.deleteById(saved.getId());
    }
}
