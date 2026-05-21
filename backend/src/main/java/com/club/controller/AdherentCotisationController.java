package com.club.controller;

import com.club.dto.CotisationDTO;
import com.club.model.Cotisation;
import com.club.model.User;
import com.club.service.CotisationService;
import com.club.service.RecuUploadService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/adherent/cotisations")
@PreAuthorize("hasAnyRole('ADHERENT', 'ADMIN', 'JOUEUR')")
public class AdherentCotisationController {

    @Autowired
    private CotisationService cotisationService;

    @Autowired
    private RecuUploadService recuUploadService;

    @GetMapping
    public ResponseEntity<List<CotisationDTO>> getMyCotisations(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        List<Cotisation> cotisations = cotisationService.getCotisationsByUser(user.getId());

        List<CotisationDTO> dtos = cotisations.stream()
                .map(CotisationDTO::fromEntity)
                .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/{id}")
    public ResponseEntity<CotisationDTO> getCotisationById(@PathVariable Long id, Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        Cotisation cotisation = cotisationService.getCotisationById(id);

        // Vérifier que la cotisation appartient bien à l'utilisateur
        if (!cotisation.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403).build();
        }

        return ResponseEntity.ok(CotisationDTO.fromEntity(cotisation));
    }

    @PostMapping
    public ResponseEntity<CotisationDTO> createCotisation(
            @RequestBody Cotisation cotisation,
            Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        
        System.out.println("=== Creating Cotisation (ADHERENT/JOUEUR) ===");
        System.out.println("Request received for user ID: " + cotisation.getUser().getId());
        System.out.println("Authenticated user ID: " + user.getId());
        
        // Vérifier que l'utilisateur ne crée une cotisation que pour lui-même
        if (!cotisation.getUser().getId().equals(user.getId())) {
            System.out.println("Permission denied: User trying to create cotisation for another user");
            return ResponseEntity.status(403).build();
        }
        
        // Récupérer l'utilisateur complet
        cotisation.setUser(user);

        Cotisation created = cotisationService.createCotisation(cotisation);
        System.out.println("Cotisation created with ID: " + created.getId());
        return ResponseEntity.ok(CotisationDTO.fromEntity(created));
    }

    @PostMapping("/{id}/upload-recu")
    public ResponseEntity<?> uploadRecu(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file,
            Authentication authentication) {
        try {
            User user = (User) authentication.getPrincipal();
            Cotisation cotisation = cotisationService.getCotisationById(id);

            // Vérifier que la cotisation appartient bien à l'utilisateur OU que c'est un ADMIN
            boolean isOwner = cotisation.getUser().getId().equals(user.getId());
            boolean isAdmin = user.getRole() == User.Role.ADMIN;
            
            if (!isOwner && !isAdmin) {
                return ResponseEntity.status(403).body(Map.of("error", "Accès non autorisé"));
            }

            // Stocker le fichier
            String fileName = recuUploadService.storeRecu(file);

            // Construire l'URL publique
            String fileDownloadUri = ServletUriComponentsBuilder.fromCurrentContextPath()
                    .path("/uploads/recus/")
                    .path(fileName)
                    .toUriString();

            // Mettre à jour la cotisation
            cotisation.setRecuPhoto(fileDownloadUri);
            cotisation.setDateUploadRecu(LocalDateTime.now());
            // Si un admin upload, on peut directement valider ou laisser en attente
            if (!isAdmin) {
                cotisation.setStatut(Cotisation.Statut.EN_ATTENTE);
            }

            Cotisation updated = cotisationService.updateCotisation(id, cotisation);

            return ResponseEntity.ok(Map.of(
                    "message", "Reçu uploadé avec succès",
                    "recuUrl", fileDownloadUri,
                    "cotisation", CotisationDTO.fromEntity(updated)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", com.club.exception.SafeErrorMessages.UPLOAD_FAILED));
        }
    }
}
