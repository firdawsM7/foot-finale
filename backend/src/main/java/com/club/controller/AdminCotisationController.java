package com.club.controller;

import com.club.dto.CotisationDTO;
import com.club.model.Cotisation;
import com.club.model.User;
import com.club.service.CotisationService;
import com.club.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/admin/cotisations")
@PreAuthorize("hasRole('ADMIN')")
public class AdminCotisationController {

    @Autowired
    private CotisationService cotisationService;

    @Autowired
    private UserService userService;

    @GetMapping
    public ResponseEntity<List<CotisationDTO>> getAllCotisations(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String saison,
            @RequestParam(required = false) String statut) {

        Cotisation.Statut statutEnum = statut != null ? Cotisation.Statut.valueOf(statut) : null;
        List<Cotisation> cotisations = cotisationService.filterCotisations(userId, saison, statutEnum);

        List<CotisationDTO> dtos = cotisations.stream()
                .map(CotisationDTO::fromEntity)
                .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/{id}")
    public ResponseEntity<CotisationDTO> getCotisationById(@PathVariable Long id) {
        Cotisation cotisation = cotisationService.getCotisationById(id);
        return ResponseEntity.ok(CotisationDTO.fromEntity(cotisation));
    }

    @PostMapping
    public ResponseEntity<CotisationDTO> createCotisation(@RequestBody Cotisation cotisation) {
        System.out.println("=== Creating Cotisation ===");
        System.out.println("Request received for user ID: " + cotisation.getUser().getId());
        
        // Récupérer l'utilisateur
        User user = userService.getUserById(cotisation.getUser().getId());
        cotisation.setUser(user);

        Cotisation created = cotisationService.createCotisation(cotisation);
        System.out.println("Cotisation created with ID: " + created.getId());
        return ResponseEntity.ok(CotisationDTO.fromEntity(created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<CotisationDTO> updateCotisation(@PathVariable Long id, @RequestBody Cotisation cotisation) {
        Cotisation updated = cotisationService.updateCotisation(id, cotisation);
        return ResponseEntity.ok(CotisationDTO.fromEntity(updated));
    }

    @PutMapping("/{id}/valider")
    public ResponseEntity<CotisationDTO> validerCotisation(@PathVariable Long id) {
        Cotisation validated = cotisationService.validerCotisation(id);
        return ResponseEntity.ok(CotisationDTO.fromEntity(validated));
    }

    @PutMapping("/{id}/rejeter")
    public ResponseEntity<CotisationDTO> rejeterCotisation(@PathVariable Long id,
            @RequestBody Map<String, String> body) {
        String motif = body.get("motif");
        Cotisation rejected = cotisationService.rejeterCotisation(id, motif);
        return ResponseEntity.ok(CotisationDTO.fromEntity(rejected));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteCotisation(@PathVariable Long id) {
        cotisationService.deleteCotisation(id);
        return ResponseEntity.ok(Map.of("message", "Cotisation supprimée"));
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStatistiques() {
        return ResponseEntity.ok(cotisationService.getStatistiques());
    }

    @GetMapping("/en-attente")
    public ResponseEntity<List<CotisationDTO>> getCotisationsEnAttente() {
        List<Cotisation> cotisations = cotisationService.getCotisationsByStatut(Cotisation.Statut.EN_ATTENTE);

        // Filtrer uniquement celles avec un reçu uploadé
        List<CotisationDTO> dtos = cotisations.stream()
                .filter(c -> c.getRecuPhoto() != null && !c.getRecuPhoto().isEmpty())
                .map(CotisationDTO::fromEntity)
                .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }
}
