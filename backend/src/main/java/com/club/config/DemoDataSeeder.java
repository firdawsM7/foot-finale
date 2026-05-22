package com.club.config;

import com.club.model.Equipe;
import com.club.model.User;
import com.club.repository.EquipeRepository;
import com.club.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * Données de démo (équipes MAS Fès) si la base Docker est vide.
 * Les mots de passe utilisateurs sont gérés par DataInitializer / PasswordHashMigrationRunner.
 */
@Component
@Order(3)
public class DemoDataSeeder implements CommandLineRunner {

    private final EquipeRepository equipeRepository;
    private final UserRepository userRepository;

    public DemoDataSeeder(EquipeRepository equipeRepository, UserRepository userRepository) {
        this.equipeRepository = equipeRepository;
        this.userRepository = userRepository;
    }

    @Override
    public void run(String... args) {
        if (equipeRepository.count() > 0) {
            return;
        }

        User encadrant = userRepository.findByEmail("coach@club.com").orElse(null);

        create("MAGHREB ASSOCIATION SPORTIVE - ÉQUIPE A", "Senior A",
                "Équipe première", encadrant);
        create("MAS FÈS - RÉSERVE", "Senior B", "Équipe réserve", encadrant);
        create("MAS FÈS - U21", "U21", "Catégorie Espoirs", encadrant);
        create("MAS FÈS - U19", "U19", "Catégorie Juniors", encadrant);
        create("MAS FÈS - FUTSAL", "Futsal", "Équipe Futsal", encadrant);

        System.out.println("✓ " + equipeRepository.count() + " équipes de démo créées.");
    }

    private void create(String nom, String categorie, String description, User encadrant) {
        Equipe equipe = new Equipe();
        equipe.setNom(nom);
        equipe.setCategorie(categorie);
        equipe.setDescription(description);
        equipe.setActive(true);
        if (encadrant != null) {
            equipe.setEncadrant(encadrant);
        }
        equipeRepository.save(equipe);
    }
}
