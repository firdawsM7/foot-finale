package com.club.config;

import com.club.model.User;
import com.club.repository.UserRepository;
import com.club.security.MultiPasswordEncoder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Migre les mots de passe en clair (ou legacy) vers BCrypt au démarrage.
 */
@Component
@Order(1)
public class PasswordHashMigrationRunner implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(PasswordHashMigrationRunner.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final MultiPasswordEncoder multiPasswordEncoder;

    @Value("${app.security.migrate-plain-passwords:true}")
    private boolean migratePlainPasswords;

    public PasswordHashMigrationRunner(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            MultiPasswordEncoder multiPasswordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.multiPasswordEncoder = multiPasswordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) {
        if (!migratePlainPasswords) {
            return;
        }

        List<User> users = userRepository.findAll();
        int migrated = 0;

        for (User user : users) {
            String stored = user.getPassword();
            if (stored == null || stored.isBlank()) {
                continue;
            }
            if (multiPasswordEncoder.looksLikeBcrypt(stored)) {
                continue;
            }
            if (isLegacyDigest(stored)) {
                log.warn(
                        "Mot de passe legacy (digest) pour {} — connexion puis migration automatique au login.",
                        user.getEmail());
                continue;
            }

            user.setPassword(passwordEncoder.encode(stored));
            userRepository.save(user);
            migrated++;
            log.info("Mot de passe hashé (BCrypt) pour l'utilisateur id={}", user.getId());
        }

        if (migrated > 0) {
            log.info("Migration mots de passe terminée : {} compte(s) mis à jour.", migrated);
        }
    }

    private boolean isLegacyDigest(String stored) {
        return stored.startsWith("{SHA-256}") || stored.startsWith("{sha256}");
    }
}
