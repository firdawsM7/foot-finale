package com.club.controller;

import com.club.model.*;
import com.club.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.club.dto.ChatMessageDto;
import com.club.model.ChatMessage;
import com.club.repository.ChatMessageRepository;
import java.util.stream.Collectors;
import java.util.List;

@RestController
@RequestMapping("/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    @Autowired
    private UserService userService;
    @Autowired
    private JoueurService joueurService;
    @Autowired
    private EquipeService equipeService;
    @Autowired
    private EntrainementService entrainementService;
    @Autowired
    private MatchService matchService;
    @Autowired
    private CotisationService cotisationService;

    // ==================== GESTION UTILISATEURS ====================

    // Liste / creation utilisateurs admin : voir AdminUserController (/admin/users)

    @GetMapping("/users/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }

    @PutMapping("/users/{id}")
    public ResponseEntity<User> updateUser(@PathVariable Long id, @RequestBody User user) {
        return ResponseEntity.ok(userService.updateUser(id, user));
    }

    @PutMapping("/users/{id}/role")
    public ResponseEntity<User> changeUserRole(@PathVariable Long id, @RequestBody User.Role role) {
        return ResponseEntity.ok(userService.changeRole(id, role));
    }

    @PutMapping("/users/{id}/toggle")
    public ResponseEntity<User> toggleUserStatus(@PathVariable Long id) {
        return ResponseEntity.ok(userService.toggleUserStatus(id));
    }

    @DeleteMapping("/users/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/users/role/{role}")
    public ResponseEntity<List<User>> getUsersByRole(@PathVariable User.Role role) {
        return ResponseEntity.ok(userService.getUsersByRole(role));
    }

    // ==================== GESTION JOUEURS ====================

    @GetMapping("/joueurs")
    public ResponseEntity<List<User>> getAllJoueursUsers() {
        return ResponseEntity.ok(userService.getUsersByRole(User.Role.JOUEUR));
    }

    @GetMapping("/joueurs-legacy")
    public ResponseEntity<List<Joueur>> getAllJoueursLegacy() {
        return ResponseEntity.ok(joueurService.getAllJoueurs());
    }

    @GetMapping("/joueurs/{id}")
    public ResponseEntity<Joueur> getJoueurById(@PathVariable Long id) {
        return ResponseEntity.ok(joueurService.getJoueurById(id));
    }

    @PostMapping("/joueurs")
    public ResponseEntity<Joueur> createJoueur(@RequestBody Joueur joueur) {
        return ResponseEntity.ok(joueurService.createJoueur(joueur));
    }

    @PutMapping("/joueurs/{id}")
    public ResponseEntity<Joueur> updateJoueur(@PathVariable Long id, @RequestBody Joueur joueur) {
        return ResponseEntity.ok(joueurService.updateJoueur(id, joueur));
    }

    @DeleteMapping("/joueurs/{id}")
    public ResponseEntity<?> deleteJoueur(@PathVariable Long id) {
        joueurService.deleteJoueur(id);
        return ResponseEntity.ok().build();
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

    @PostMapping("/equipes")
    public ResponseEntity<Equipe> createEquipe(@RequestBody Equipe equipe) {
        return ResponseEntity.ok(equipeService.createEquipe(equipe));
    }

    @PutMapping("/equipes/{id}")
    public ResponseEntity<Equipe> updateEquipe(@PathVariable Long id, @RequestBody Equipe equipe) {
        return ResponseEntity.ok(equipeService.updateEquipe(id, equipe));
    }

    @DeleteMapping("/equipes/{id}")
    public ResponseEntity<?> deleteEquipe(@PathVariable Long id) {
        equipeService.deleteEquipe(id);
        return ResponseEntity.ok().build();
    }

    // ==================== GESTION ENTRAÎNEMENTS ====================

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

    @PostMapping("/entrainements")
    public ResponseEntity<Entrainement> createEntrainement(@RequestBody Entrainement entrainement) {
        return ResponseEntity.ok(entrainementService.createEntrainement(entrainement));
    }

    @PutMapping("/entrainements/{id}")
    public ResponseEntity<Entrainement> updateEntrainement(@PathVariable Long id,
            @RequestBody Entrainement entrainement) {
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