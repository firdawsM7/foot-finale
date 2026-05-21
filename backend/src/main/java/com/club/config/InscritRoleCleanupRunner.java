package com.club.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Supprime définitivement les comptes et données liées au rôle INSCRIT (obsolète).
 */
@Component
@Order(0)
public class InscritRoleCleanupRunner implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(InscritRoleCleanupRunner.class);

    private final JdbcTemplate jdbcTemplate;

    public InscritRoleCleanupRunner(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    @Transactional
    public void run(String... args) {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM users WHERE role = 'INSCRIT'", Integer.class);
        if (count == null || count == 0) {
            jdbcTemplate.update("DELETE FROM document_type_config WHERE role = 'INSCRIT'");
            return;
        }

        log.info("Suppression de {} compte(s) INSCRIT et données associées...", count);

        jdbcTemplate.update(
                "DELETE d FROM documents d INNER JOIN users u ON d.user_id = u.id WHERE u.role = 'INSCRIT'");
        jdbcTemplate.update(
                "DELETE c FROM cotisations c INNER JOIN users u ON c.user_id = u.id WHERE u.role = 'INSCRIT'");
        jdbcTemplate.update(
                "DELETE n FROM message_notifications n INNER JOIN users u ON n.user_id = u.id WHERE u.role = 'INSCRIT'");
        jdbcTemplate.update(
                "DELETE m FROM chat_messages m INNER JOIN users u ON m.sender_id = u.id WHERE u.role = 'INSCRIT'");
        jdbcTemplate.update(
                "DELETE m FROM chat_messages m INNER JOIN users u ON m.recipient_id = u.id WHERE u.role = 'INSCRIT'");
        jdbcTemplate.update(
                "DELETE p FROM player_technical_notes p INNER JOIN users u ON p.encadrant_id = u.id WHERE u.role = 'INSCRIT'");
        jdbcTemplate.update(
                "UPDATE equipes e INNER JOIN users u ON e.encadrant_id = u.id SET e.encadrant_id = NULL WHERE u.role = 'INSCRIT'");
        jdbcTemplate.update(
                "UPDATE entrainements t INNER JOIN users u ON t.encadrant_id = u.id SET t.encadrant_id = NULL WHERE u.role = 'INSCRIT'");
        int deleted = jdbcTemplate.update("DELETE FROM users WHERE role = 'INSCRIT'");
        jdbcTemplate.update("DELETE FROM document_type_config WHERE role = 'INSCRIT'");

        log.info("{} compte(s) INSCRIT supprimé(s) de la base de données.", deleted);
    }
}
