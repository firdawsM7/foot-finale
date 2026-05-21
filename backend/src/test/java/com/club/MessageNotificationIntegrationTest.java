package com.club;

import com.club.model.MessageNotification;
import com.club.model.User;
import com.club.repository.MessageNotificationRepository;
import com.club.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class MessageNotificationIntegrationTest {

    @Autowired
    private MessageNotificationRepository notificationRepository;

    @Autowired
    private UserRepository userRepository;

    @Test
    void saveNotification_usesIsReadColumn() {
        User user = userRepository.findByEmail("admin@gmail.com").orElseThrow();

        MessageNotification notification = new MessageNotification();
        notification.setUser(user);
        notification.setType(MessageNotification.NotificationType.BROADCAST);
        notification.setTitle("Test");
        notification.setBody("JUnit notification");
        notification.setRead(false);
        notification.setCreatedAt(LocalDateTime.now());

        MessageNotification saved = notificationRepository.save(notification);
        assertNotNull(saved.getId());
        assertFalse(saved.isRead());

        notificationRepository.deleteById(saved.getId());
    }
}
