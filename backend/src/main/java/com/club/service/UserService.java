package com.club.service;

import com.club.exception.BusinessException;
import com.club.model.RegistrationStatus;
import com.club.model.User;
import com.club.repository.UserRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class UserService implements UserDetailsService {

        private final UserRepository userRepository;
        private final PasswordEncoder passwordEncoder;

        public UserService(
                        UserRepository userRepository,
                        PasswordEncoder passwordEncoder) {
                this.userRepository = userRepository;
                this.passwordEncoder = passwordEncoder;
        }

        @Override
        public UserDetails loadUserByUsername(String email)
                        throws UsernameNotFoundException {

                return userRepository.findByEmail(email)
                                .orElseThrow(() -> new UsernameNotFoundException(
                                                "Identifiants invalides"));
        }

        public User register(User user) {
                user.setEmail(com.club.security.InputSanitizer.sanitizeEmail(user.getEmail()));
                user.setNom(com.club.security.InputSanitizer.sanitizeName(user.getNom()));
                user.setPrenom(com.club.security.InputSanitizer.sanitizeName(user.getPrenom()));
                if (user.getTelephone() != null) {
                        user.setTelephone(com.club.security.InputSanitizer.sanitizeText(user.getTelephone()));
                }
                if (user.getAdresse() != null) {
                        user.setAdresse(com.club.security.InputSanitizer.sanitizeText(user.getAdresse()));
                }

                if (userRepository.existsByEmail(user.getEmail())) {
                        throw new BusinessException("Email déjà utilisé");
                }

                user.setPassword(passwordEncoder.encode(user.getPassword()));
                user.setRole(User.Role.ADHERENT);
                user.setRegistrationStatus(RegistrationStatus.PENDING);
                user.setDateInscription(LocalDateTime.now());
                return userRepository.save(user);
        }

        public User createUserByAdmin(User user) {
                if (userRepository.existsByEmail(user.getEmail())) {
                        throw new BusinessException("Email déjà utilisé");
                }

                // Generate unique activation token
                String activationToken = UUID.randomUUID().toString();
                
                user.setPassword(null);  // No initial password
                user.setActif(false);
                user.setAccountStatus(User.AccountStatus.ACTIVATION_REQUISE);
                user.setRegistrationStatus(RegistrationStatus.PENDING);
                user.setActivationToken(activationToken);
                user.setDateInscription(LocalDateTime.now());
                
                return userRepository.save(user);
        }

        // Activate account on first login
        public User activateAccount(String email, String newPassword, String activationToken) {
                User user = userRepository.findByEmail(email)
                                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

                // Verify token
                if (!activationToken.equals(user.getActivationToken())) {
                        throw new BusinessException("Token d'activation invalide");
                }

                // Check if account needs activation
                if (user.getAccountStatus() != User.AccountStatus.ACTIVATION_REQUISE) {
                        throw new BusinessException("Ce compte est déjà activé");
                }

                // Validate password
                if (newPassword == null || newPassword.length() < 6) {
                        throw new BusinessException("Le mot de passe doit contenir au moins 6 caractères");
                }

                // Activate the account
                user.setPassword(passwordEncoder.encode(newPassword));
                user.setActif(true);
                user.setAccountStatus(User.AccountStatus.ACTIF);
                user.setActivationToken(null);  // Remove token after activation
                user.setDerniereConnexion(LocalDateTime.now());

                return userRepository.save(user);
        }

        // Check if user needs activation
        public Map<String, Object> checkActivationStatus(String email) {
                return userRepository.findByEmail(email)
                                .map(user -> {
                                        Map<String, Object> response = new HashMap<>();
                                        if (user.getAccountStatus() == User.AccountStatus.ACTIVATION_REQUISE) {
                                                response.put("needsActivation", true);
                                                response.put("activationToken", user.getActivationToken());
                                        } else {
                                                response.put("needsActivation", false);
                                        }
                                        response.put("message", com.club.exception.SafeErrorMessages.OPERATION_FAILED);
                                        return response;
                                })
                                .orElseGet(() -> Map.of(
                                                "needsActivation", false,
                                                "message", com.club.exception.SafeErrorMessages.OPERATION_FAILED));
        }

        public User createUser(User user) {
                user.setPassword(passwordEncoder.encode(user.getPassword()));
                user.setDateInscription(LocalDateTime.now());
                return userRepository.save(user);
        }

        public User updateUser(Long id, User userDetails) {

                User user = userRepository.findById(id)
                                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

                user.setNom(userDetails.getNom());
                user.setPrenom(userDetails.getPrenom());
                user.setTelephone(userDetails.getTelephone());
                user.setAdresse(userDetails.getAdresse());
                user.setDateNaissance(userDetails.getDateNaissance());
                user.setPhoto(userDetails.getPhoto());

                if (userDetails.getPassword() != null &&
                                !userDetails.getPassword().isEmpty()) {

                        user.setPassword(
                                        passwordEncoder.encode(userDetails.getPassword()));
                }

                return userRepository.save(user);
        }

        public User changeRole(Long id, User.Role role) {
                User user = userRepository.findById(id)
                                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
                user.setRole(role);
                return userRepository.save(user);
        }

        public User toggleUserStatus(Long id) {
                User user = userRepository.findById(id)
                                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
                user.setActif(!user.getActif());
                return userRepository.save(user);
        }

        public void updateLastLogin(String email) {
                User user = userRepository.findByEmail(email)
                                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
                user.setDerniereConnexion(LocalDateTime.now());
                userRepository.save(user);
        }

        public void migratePasswordIfNeeded(String email, String rawPassword) {
                User user = userRepository.findByEmail(email)
                                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

                String stored = user.getPassword();
                if (stored == null)
                        return;

                boolean looksLikeBcrypt = stored.startsWith("$2a$") || stored.startsWith("$2b$")
                                || stored.startsWith("$2y$");

                if (!looksLikeBcrypt && passwordEncoder.matches(rawPassword, stored)) {
                        user.setPassword(passwordEncoder.encode(rawPassword));
                        userRepository.save(user);
                }
        }

        public List<User> getAllUsers() {
                return userRepository.findAll();
        }

        public List<User> getUsersByRole(User.Role role) {
                return userRepository.findByRole(role);
        }

        public User getUserById(Long id) {
                return userRepository.findById(id)
                                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
        }

        public void deleteUser(Long id) {
                userRepository.deleteById(id);
        }

        public User updateUserPhoto(Long id, String photoUrl) {
                User user = userRepository.findById(id)
                                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
                user.setPhoto(photoUrl);
                return userRepository.save(user);
        }
}
