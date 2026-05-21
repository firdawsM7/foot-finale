package com.club.repository;

import com.club.model.ChatMessage;
import com.club.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    List<ChatMessage> findByTeam_IdOrderByTimestampAsc(Long teamId);

    List<ChatMessage> findByTeam_IdOrderByTimestampDesc(Long teamId);

    @Query("SELECT m FROM ChatMessage m WHERE m.team IS NULL ORDER BY m.timestamp DESC")
    List<ChatMessage> findAllAdminMessages();

    List<ChatMessage> findByTeam_Id(Long teamId);

    @Query("SELECT m FROM ChatMessage m WHERE m.team IS NULL AND " +
           "(m.recipientId IS NULL AND m.recipientRole IS NULL " +
           "OR m.recipientId = :userId " +
           "OR m.recipientRole = :role) " +
           "ORDER BY m.timestamp DESC")
    List<ChatMessage> findAdminMessagesForUserAndRole(@Param("userId") Long userId, @Param("role") User.Role role);

    @Query("SELECT m FROM ChatMessage m WHERE m.team IS NULL AND " +
           "((m.sender.id = :userId AND m.recipientId = :adminId) OR " +
           "(m.sender.id = :adminId AND m.recipientId = :userId)) " +
           "ORDER BY m.timestamp ASC")
    List<ChatMessage> findPrivateConversationWithAdmin(@Param("userId") Long userId, @Param("adminId") Long adminId);

    List<ChatMessage> findBySenderOrderByTimestampDesc(User sender);
}
