package com.club.util;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * Utilitaire pour générer des hashes BCrypt
 * Utilisation: java PasswordHashGenerator.java <mot_de_passe>
 */
public class PasswordHashGenerator {
    public static void main(String[] args) {
        if (args.length == 0) {
            System.out.println("Usage: java PasswordHashGenerator <mot_de_passe>");
            System.out.println("Exemple: java PasswordHashGenerator admin123");
            System.exit(1);
        }
        
        String password = args[0];
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String hash = encoder.encode(password);
        
        System.out.println("Mot de passe: " + password);
        System.out.println("Hash BCrypt: " + hash);
        System.out.println("\nCommande SQL pour mettre à jour:");
        System.out.println("UPDATE users SET password = '" + hash + "' WHERE email = 'superadmin@club.com';");
    }
}

