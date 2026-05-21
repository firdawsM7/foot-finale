package com.club.controller;

import com.club.dto.PlayerTechnicalNoteDto;
import com.club.model.Joueur;
import com.club.model.PlayerTechnicalNote;
import com.club.model.User;
import com.club.repository.JoueurRepository;
import com.club.repository.PlayerTechnicalNoteRepository;
import com.club.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/encadrant/players")
@PreAuthorize("hasAnyRole('ADMIN', 'ENCADRANT')")
public class PlayerTechnicalNoteController {

        @Autowired
        private PlayerTechnicalNoteRepository noteRepository;

        @Autowired
        private JoueurRepository joueurRepository;

        @Autowired
        private UserRepository userRepository;

        @GetMapping("/{playerId}/notes")
        public List<PlayerTechnicalNoteDto> getPlayerNotes(@PathVariable Long playerId) {
                return noteRepository.findByPlayerIdOrderByCreatedAtDesc(playerId).stream()
                                .map(this::convertToDto)
                                .collect(Collectors.toList());
        }

        @PostMapping("/{playerId}/notes")
        public PlayerTechnicalNoteDto createNote(
                        @PathVariable Long playerId,
                        @RequestBody PlayerTechnicalNoteDto dto,
                        Authentication authentication) {

                Joueur player = joueurRepository.findById(playerId)
                                .orElseThrow(() -> new RuntimeException("Player not found"));

                String email = authentication.getName();
                User encadrant = userRepository.findByEmail(email)
                                .orElseThrow(() -> new RuntimeException("User not found"));

                PlayerTechnicalNote note = new PlayerTechnicalNote(
                                player,
                                encadrant,
                                dto.getTechnicalRating(),
                                dto.getTacticalRating(),
                                dto.getPhysicalRating(),
                                dto.getStrengths(),
                                dto.getWeaknesses(),
                                dto.getObservation());

                PlayerTechnicalNote saved = noteRepository.save(note);
                return convertToDto(saved);
        }

        private PlayerTechnicalNoteDto convertToDto(PlayerTechnicalNote note) {
                return new PlayerTechnicalNoteDto(
                                note.getId(),
                                note.getPlayer().getId(),
                                note.getEncadrant().getId(),
                                note.getEncadrant().getPrenom() + " " + note.getEncadrant().getNom(),
                                note.getTechnicalRating(),
                                note.getTacticalRating(),
                                note.getPhysicalRating(),
                                note.getStrengths(),
                                note.getWeaknesses(),
                                note.getObservation(),
                                note.getCreatedAt());
        }
}
