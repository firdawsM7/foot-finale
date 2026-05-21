package com.club.repository;

import com.club.model.MessageNotification;
import com.club.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MessageNotificationRepository extends JpaRepository<MessageNotification, Long> {

    List<MessageNotification> findByUserOrderByCreatedAtDesc(User user);

    @Query("SELECT COUNT(n) FROM MessageNotification n WHERE n.user = :user AND n.readFlag = false")
    long countByUserAndIsReadFalse(@Param("user") User user);

    @Modifying
    @Query("UPDATE MessageNotification n SET n.readFlag = true WHERE n.user.id = :userId")
    int markAllReadForUser(@Param("userId") Long userId);
}
