package com.club.security;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.MessageDigestPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

public class MultiPasswordEncoder implements PasswordEncoder {

    private final BCryptPasswordEncoder bcrypt = new BCryptPasswordEncoder();
    private final PasswordEncoder sha256 = new MessageDigestPasswordEncoder("SHA-256");

    @Override
    public String encode(CharSequence rawPassword) {
        return bcrypt.encode(rawPassword);
    }

    @Override
    public boolean matches(CharSequence rawPassword, String encodedPassword) {
        if (encodedPassword == null) return false;

        // Try bcrypt first
        try {
            if (bcrypt.matches(rawPassword, encodedPassword)) return true;
        } catch (Exception ignored) {}

        // SHA-256 legacy (jusqu'à migration complète au login)
        try {
            if (sha256.matches(rawPassword, encodedPassword)) return true;
        } catch (Exception ignored) {}

        return false;
    }

    public boolean looksLikeBcrypt(String encodedPassword) {
        return encodedPassword != null && (encodedPassword.startsWith("$2a$") || encodedPassword.startsWith("$2b$") || encodedPassword.startsWith("$2y$"));
    }
}
