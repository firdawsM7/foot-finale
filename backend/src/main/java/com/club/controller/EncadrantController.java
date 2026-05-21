package com.club.controller;

import com.club.model.*;
import com.club.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/encadrant")
@PreAuthorize("hasAnyRole('ADMIN', 'ENCADRANT')")
public class EncadrantController {
    
    @Autowired private UserService userService;
    @Autowired private JoueurService joueurService;
    @Autowired private EquipeService equipeService;
    @Autowired private EntrainementService entrainementService;
    @Autowired private MatchService matchService;
    
    // ==================== GESTION JOUEURS ====================
    
    @GetMapping("/joueurs")
    public ResponseEntity<List<User>> getAllJoueurs() {
        return ResponseEntity.ok(userService.getUsersByRole(User.Role.JOUEUR));
    }
    
    @GetMapping("/joueurs/{id}")
    public ResponseEntity<Joueur> getJoueurById(@PathVariable Long id) {
        return ResponseEntity.ok(joueurService.getJoueurById(id));
    }
    
    @GetMapping("/joueurs/equipe/{equipeId}")
    public ResponseEntity<List<Joueur>> getJoueursByEquipe(@PathVariable Long equipeId) {
        return ResponseEntity.ok(joueurService.getJoueursByEquipe(equipeId));
    }
    
    @PostMapping("/joueurs")
    public ResponseEntity<Joueur> createJoueur(@RequestBody Joueur joueur) {
        return ResponseEntity.ok(joueurService.createJoueur(joueur));
    }
    
    @PutMapping("/joueurs/{id}")
    public ResponseEntity<Joueur> updateJoueur(@PathVariable Long id, @RequestBody Joueur joueur) {
        return ResponseEntity.ok(joueurService.updateJoueur(id, joueur));
    }
    
    // ==================== GESTION ÉQUIPES ====================
    
    @GetMapping("/equipes")
    public ResponseEntity<List<Equipe>> getAllEquipes() {
        return ResponseEntity.ok(equipeService.getAllEquipes());
    }
    
    @GetMapping("/equipes/{id}")
    public ResponseEntity<Equipe> getEquipeById(@PathVariable Long id) {
        return ResponseEntity.ok(equipeService.getEquipeById(id));
    }
    
    @GetMapping("/mes-equipes/{encadrantId}")
    public ResponseEntity<List<Equipe>> getMesEquipes(@PathVariable Long encadrantId) {
        return ResponseEntity.ok(equipeService.getEquipesByEncadrant(encadrantId));
    }
    
    @PostMapping("/equipes")
    public ResponseEntity<Equipe> createEquipe(@RequestBody Equipe equipe) {
        return ResponseEntity.ok(equipeService.createEquipe(equipe));
    }
    
    @PutMapping("/equipes/{id}")
    public ResponseEntity<Equipe> updateEquipe(@PathVariable Long id, @RequestBody Equipe equipe) {
        return ResponseEntity.ok(equipeService.updateEquipe(id, equipe));
    }
    
    // ==================== GESTION ENTRAÎNEMENTS ====================
    
    @GetMapping("/entrainements")
    public ResponseEntity<List<Entrainement>> getAllEntrainements() {
        return ResponseEntity.ok(entrainementService.getAllEntrainements());
    }
    
    @GetMapping("/entrainements/mes-seances/{encadrantId}")
    public ResponseEntity<List<Entrainement>> getMesSeances(@PathVariable Long encadrantId) {
        List<Entrainement> allEntrainements = entrainementService.getAllEntrainements();
        // Filter trainings assigned to this encadrant
        List<Entrainement> mesSeances = allEntrainements.stream()
            .filter(e -> e.getEncadrant() != null && e.getEncadrant().getId().equals(encadrantId))
            .collect(java.util.stream.Collectors.toList());
        return ResponseEntity.ok(mesSeances);
    }
    
    @GetMapping("/entrainements/{id}")
    public ResponseEntity<Entrainement> getEntrainementById(@PathVariable Long id) {
        return ResponseEntity.ok(entrainementService.getEntrainementById(id));
    }
    
    @GetMapping("/entrainements/equipe/{equipeId}")
    public ResponseEntity<List<Entrainement>> getEntrainementsByEquipe(@PathVariable Long equipeId) {
        return ResponseEntity.ok(entrainementService.getEntrainementsByEquipe(equipeId));
    }
    
    @PostMapping("/entrainements")
    public ResponseEntity<Entrainement> createEntrainement(@RequestBody Entrainement entrainement) {
        return ResponseEntity.ok(entrainementService.createEntrainement(entrainement));
    }
    
    @PutMapping("/entrainements/{id}")
    public ResponseEntity<Entrainement> updateEntrainement(@PathVariable Long id, @RequestBody Entrainement entrainement) {
        return ResponseEntity.ok(entrainementService.updateEntrainement(id, entrainement));
    }
    
    @DeleteMapping("/entrainements/{id}")
    public ResponseEntity<?> deleteEntrainement(@PathVariable Long id) {
        entrainementService.deleteEntrainement(id);
        return ResponseEntity.ok().build();
    }
    
    // ==================== GESTION MATCHS ====================
    
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
    
    @PostMapping("/matchs")
    public ResponseEntity<Match> createMatch(@RequestBody Match match) {
        return ResponseEntity.ok(matchService.createMatch(match));
    }
    
    @PutMapping("/matchs/{id}")
    public ResponseEntity<Match> updateMatch(@PathVariable Long id, @RequestBody Match match) {
        return ResponseEntity.ok(matchService.updateMatch(id, match));
    }
    
    @DeleteMapping("/matchs/{id}")
    public ResponseEntity<?> deleteMatch(@PathVariable Long id) {
        matchService.deleteMatch(id);
        return ResponseEntity.ok().build();
    }
}