package com.club.controller;

import com.club.model.*;
import com.club.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/adherent")
@PreAuthorize("hasAnyRole('ADMIN', 'ENCADRANT', 'ADHERENT', 'JOUEUR')")
public class AdherentController {
    
    @Autowired private UserService userService;
    @Autowired private JoueurService joueurService;
    @Autowired private EquipeService equipeService;
    @Autowired private EntrainementService entrainementService;
    @Autowired private MatchService matchService;
    @Autowired private CotisationService cotisationService;
    
    // ==================== PROFIL UTILISATEUR ====================
    
    @GetMapping("/profil/{id}")
    public ResponseEntity<User> getProfil(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }
    
    @PutMapping("/profil/{id}")
    public ResponseEntity<User> updateProfil(@PathVariable Long id, @RequestBody User user) {
        return ResponseEntity.ok(userService.updateUser(id, user));
    }
    
    // ==================== CONSULTATION JOUEURS ====================
    
    @GetMapping("/joueurs")
    public ResponseEntity<List<Joueur>> getAllJoueurs() {
        return ResponseEntity.ok(joueurService.getAllJoueurs());
    }
    
    @GetMapping("/joueurs/{id}")
    public ResponseEntity<Joueur> getJoueurById(@PathVariable Long id) {
        return ResponseEntity.ok(joueurService.getJoueurById(id));
    }
    
    @GetMapping("/joueurs/equipe/{equipeId}")
    public ResponseEntity<List<Joueur>> getJoueursByEquipe(@PathVariable Long equipeId) {
        return ResponseEntity.ok(joueurService.getJoueursByEquipe(equipeId));
    }
    
    // ==================== CONSULTATION ÉQUIPES ====================
    
    @GetMapping("/equipes")
    public ResponseEntity<List<Equipe>> getAllEquipes() {
        return ResponseEntity.ok(equipeService.getAllEquipes());
    }
    
    @GetMapping("/equipes/{id}")
    public ResponseEntity<Equipe> getEquipeById(@PathVariable Long id) {
        return ResponseEntity.ok(equipeService.getEquipeById(id));
    }
    
    // ==================== CONSULTATION ENTRAÎNEMENTS ====================
    
    @GetMapping("/entrainements")
    public ResponseEntity<List<Entrainement>> getAllEntrainements() {
        return ResponseEntity.ok(entrainementService.getAllEntrainements());
    }
    
    @GetMapping("/entrainements/{id}")
    public ResponseEntity<Entrainement> getEntrainementById(@PathVariable Long id) {
        return ResponseEntity.ok(entrainementService.getEntrainementById(id));
    }
    
    @GetMapping("/entrainements/equipe/{equipeId}")
    public ResponseEntity<List<Entrainement>> getEntrainementsByEquipe(@PathVariable Long equipeId) {
        return ResponseEntity.ok(entrainementService.getEntrainementsByEquipe(equipeId));
    }
    
    // ==================== CONSULTATION MATCHS ====================
    
    @GetMapping("/matchs")
    public ResponseEntity<List<Match>> getAllMatchs() {
        return ResponseEntity.ok(matchService.getAllMatchs());
    }
    
    @GetMapping("/matchs/{id}")
    public ResponseEntity<Match> getMatchById(@PathVariable Long id) {
        return ResponseEntity.ok(matchService.getMatchById(id));
    }
    
    @GetMapping("/matchs/equipe/{equipeId}")
    public ResponseEntity<List<Match>> getMatchsByEquipe(@PathVariable Long equipeId) {
        return ResponseEntity.ok(matchService.getMatchsByEquipe(equipeId));
    }
    
    // ==================== GESTION COTISATIONS ====================
    
    @GetMapping("/cotisations/mes-cotisations/{userId}")
    public ResponseEntity<List<Cotisation>> getMesCotisations(@PathVariable Long userId) {
        return ResponseEntity.ok(cotisationService.getCotisationsByUser(userId));
    }
}