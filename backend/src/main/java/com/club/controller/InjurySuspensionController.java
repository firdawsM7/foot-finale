package com.club.controller;

import com.club.dto.InjurySuspensionDto;
import com.club.model.InjurySuspension;
import com.club.model.Joueur;
import com.club.repository.InjurySuspensionRepository;
import com.club.repository.JoueurRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/encadrant")
@PreAuthorize("hasAnyRole('ADMIN', 'ENCADRANT')")
public class InjurySuspensionController {

        @Autowired
        private InjurySuspensionRepository alertRepository;

        @Autowired
        private JoueurRepository joueurRepository;

        @GetMapping("/alerts")
        public List<InjurySuspensionDto> getAllActiveAlerts() {
                return alertRepository.findByStatus(InjurySuspension.Status.ACTIVE).stream()
                                .map(this::convertToDto)
                                .collect(Collectors.toList());
        }

        @GetMapping("/players/{playerId}/alerts")
        public List<InjurySuspensionDto> getPlayerAlerts(@PathVariable Long playerId) {
                return alertRepository.findByPlayerIdAndStatus(playerId, InjurySuspension.Status.ACTIVE).stream()
                                .map(this::convertToDto)
                                .collect(Collectors.toList());
        }

        @PostMapping("/players/{playerId}/alerts")
        public InjurySuspensionDto createAlert(
                        @PathVariable Long playerId,
                        @RequestBody InjurySuspensionDto dto) {

                Joueur player = joueurRepository.findById(playerId)
                                .orElseThrow(() -> new RuntimeException("Player not found"));

                InjurySuspension alert = new InjurySuspension(
                                player,
                                InjurySuspension.AlertType.valueOf(dto.getType()),
                                InjurySuspension.Severity.valueOf(dto.getSeverity()),
                                dto.getDescription(),
                                dto.getStartDate(),
                                dto.getEstimatedEndDate(),
                                InjurySuspension.Status.ACTIVE,
                                dto.getRestrictions());

                InjurySuspension saved = alertRepository.save(alert);
                return convertToDto(saved);
        }

        @PutMapping("/alerts/{alertId}/status")
        public InjurySuspensionDto updateAlertStatus(
                        @PathVariable Long alertId,
                        @RequestParam String status) {

                InjurySuspension alert = alertRepository.findById(alertId)
                                .orElseThrow(() -> new RuntimeException("Alert not found"));

                alert.setStatus(InjurySuspension.Status.valueOf(status));
                InjurySuspension updated = alertRepository.save(alert);
                return convertToDto(updated);
        }

        private InjurySuspensionDto convertToDto(InjurySuspension alert) {
                return new InjurySuspensionDto(
                                alert.getId(),
                                alert.getPlayer().getId(),
                                alert.getPlayer().getPrenom() + " " + alert.getPlayer().getNom(),
                                alert.getType().name(),
                                alert.getSeverity().name(),
                                alert.getDescription(),
                                alert.getStartDate(),
                                alert.getEstimatedEndDate(),
                                alert.getStatus().name(),
                                alert.getRestrictions());
        }
}
