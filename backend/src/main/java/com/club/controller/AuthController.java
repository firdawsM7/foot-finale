package com.club.controller;

import com.club.exception.BusinessException;
import com.club.exception.SafeErrorMessages;
import com.club.model.User;
import com.club.security.JwtUtil;
import com.club.service.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/auth")
// @CrossOrigin(origins = "*")
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private UserService userService;


    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody User user) {
        try {
            User createdUser = userService.register(user);
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Inscription réussie");
            response.put("user", createdUser);
            return ResponseEntity.ok(response);
        } catch (BusinessException e) {
            logger.debug("Inscription refusée: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.REGISTER_FAILED));
        } catch (Exception e) {
            logger.error("Erreur inscription", e);
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.OPERATION_FAILED));
        }
    }

    @PostMapping("/check-status")
    public ResponseEntity<?> checkActivationStatus(@RequestBody Map<String, String> request) {
        try {
            String email = request.get("email");
            if (email == null || email.isBlank()) {
                return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.VALIDATION_FAILED));
            }

            Map<String, Object> status = userService.checkActivationStatus(email);
            return ResponseEntity.ok(status);
        } catch (Exception e) {
            logger.debug("Vérification statut refusée");
            return ResponseEntity.ok(Map.of(
                    "needsActivation", false,
                    "message", SafeErrorMessages.OPERATION_FAILED
            ));
        }
    }

    // NEW: Activate account (first-time login)
    @PostMapping("/activate")
    public ResponseEntity<?> activateAccount(@RequestBody Map<String, String> request) {
        try {
            String email = request.get("email");
            String password = request.get("password");
            String activationToken = request.get("activationToken");

            if (email == null || password == null || activationToken == null) {
                return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.VALIDATION_FAILED));
            }

            // Activate the account
            User user = userService.activateAccount(email, password, activationToken);

            // Generate JWT token
            String token = jwtUtil.generateToken(user);

            logger.info("Compte activé avec succès: {}", email);

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Compte activé avec succès");
            response.put("token", token);
            
            Map<String, Object> userMap = new HashMap<>();
            userMap.put("id", user.getId());
            userMap.put("email", user.getEmail());
            userMap.put("nom", user.getNom());
            userMap.put("prenom", user.getPrenom());
            userMap.put("role", user.getRole().toString());
            userMap.put("equipeId", user.getEquipeId());
            response.put("user", userMap);

            return ResponseEntity.ok(response);
        } catch (BusinessException e) {
            logger.debug("Activation refusée: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.ACTIVATION_FAILED));
        } catch (Exception e) {
            logger.error("Erreur lors de l'activation", e);
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.OPERATION_FAILED));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String email = credentials != null ? credentials.get("email") : null;
        String password = credentials != null ? credentials.get("password") : null;

        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.VALIDATION_FAILED));
        }

        try {
            User user = (User) userService.loadUserByUsername(email);

            if (user.getAccountStatus() == User.AccountStatus.SUSPENDU) {
                logger.warn("Connexion refusée (compte suspendu)");
                return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.AUTH_FAILED));
            }

            if (user.getAccountStatus() == User.AccountStatus.ACTIVATION_REQUISE
                    || user.getPassword() == null) {
                if (password == null || password.isEmpty()) {
                    return activationRequiredResponse(user);
                }
            }

            if (password == null || password.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.AUTH_FAILED));
            }

            logger.info("Tentative de connexion");

            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(email, password));

            User authenticatedUser = (User) authentication.getPrincipal();

            if (authenticatedUser.getAccountStatus() == User.AccountStatus.ACTIVATION_REQUISE) {
                return activationRequiredResponse(authenticatedUser);
            }

            String token = jwtUtil.generateToken(authenticatedUser);
            userService.updateLastLogin(email);
            userService.migratePasswordIfNeeded(email, password);

            Map<String, Object> response = new HashMap<>();
            response.put("token", token);

            Map<String, Object> userMap = new HashMap<>();
            userMap.put("id", authenticatedUser.getId());
            userMap.put("email", authenticatedUser.getEmail());
            userMap.put("nom", authenticatedUser.getNom());
            userMap.put("prenom", authenticatedUser.getPrenom());
            userMap.put("role", authenticatedUser.getRole().toString());
            userMap.put("equipeId", authenticatedUser.getEquipeId());
            response.put("user", userMap);

            logger.info("Connexion réussie");
            return ResponseEntity.ok(response);
        } catch (UsernameNotFoundException e) {
            logger.warn("Tentative de connexion échouée (utilisateur inconnu)");
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.AUTH_FAILED));
        } catch (BadCredentialsException e) {
            logger.warn("Tentative de connexion échouée");
            return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.AUTH_FAILED));
        } catch (Exception e) {
            logger.error("Erreur lors de la connexion", e);
            return ResponseEntity.status(500).body(Map.of("error", SafeErrorMessages.GENERIC));
        }
    }

    private ResponseEntity<Map<String, Object>> activationRequiredResponse(User user) {
        Map<String, Object> body = new HashMap<>();
        body.put("error", SafeErrorMessages.AUTH_FAILED);
        body.put("needsActivation", true);
        body.put("activationToken", user.getActivationToken() != null ? user.getActivationToken() : "");
        body.put("message", SafeErrorMessages.OPERATION_FAILED);
        return ResponseEntity.status(403).body(body);
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {
        if (authentication != null && authentication.isAuthenticated()) {
            User user = (User) authentication.getPrincipal();
            return ResponseEntity.ok(user);
        }
        return ResponseEntity.status(401).body(Map.of("error", SafeErrorMessages.ACCESS_DENIED));
    }
}