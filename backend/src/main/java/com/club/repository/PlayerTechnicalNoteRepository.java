package com.club.repository;

import com.club.model.PlayerTechnicalNote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PlayerTechnicalNoteRepository extends JpaRepository<PlayerTechnicalNote, Long> {
    List<PlayerTechnicalNote> findByPlayerIdOrderByCreatedAtDesc(Long playerId);
}
