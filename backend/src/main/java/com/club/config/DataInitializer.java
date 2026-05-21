package com.club.config;

import com.club.model.RegistrationStatus;
import com.club.model.User;
import com.club.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        // Check if users already exist
        if (userRepository.count() > 0) {
            System.out.println("Database already initialized with " + userRepository.count() + " users.");
            return;
        }

        System.out.println("Initializing database with test users...");

        // Create Admin user
        User admin = new User();
        admin.setEmail("admin@club.com");
        admin.setPassword(passwordEncoder.encode("password"));
        admin.setNom("Admin");
        admin.setPrenom("System");
        admin.setRole(User.Role.ADMIN);
        admin.setActif(true);
        admin.setTelephone("0600000001");
        admin.setAdresse("1 Rue du Club");
        admin.setAccountStatus(User.AccountStatus.ACTIF);
        admin.setRegistrationStatus(RegistrationStatus.ACTIVE);
        userRepository.save(admin);
        System.out.println("✓ Admin user created: admin@club.com / password");

        // Create Coach user
        User coach = new User();
        coach.setEmail("coach@club.com");
        coach.setPassword(passwordEncoder.encode("password"));
        coach.setNom("Dupont");
        coach.setPrenom("Jean");
        coach.setRole(User.Role.ENCADRANT);
        coach.setActif(true);
        coach.setAccountStatus(User.AccountStatus.ACTIF);
        coach.setRegistrationStatus(RegistrationStatus.ACTIVE);
        coach.setTelephone("0600000002");
        coach.setAdresse("2 Rue du Stade");
        userRepository.save(coach);
        System.out.println("✓ Coach user created: coach@club.com / password");

        // Create Member user
        User member = new User();
        member.setEmail("member@club.com");
        member.setPassword(passwordEncoder.encode("password"));
        member.setNom("Martin");
        member.setPrenom("Pierre");
        member.setRole(User.Role.ADHERENT);
        member.setActif(true);
        member.setAccountStatus(User.AccountStatus.ACTIF);
        member.setRegistrationStatus(RegistrationStatus.ACTIVE);
        member.setTelephone("0600000003");
        member.setAdresse("3 Avenue du Sport");
        userRepository.save(member);
        System.out.println("✓ Member user created: member@club.com / password");

        System.out.println("Database initialization completed successfully!");
    }
}
