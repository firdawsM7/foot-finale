package com.club.security;

import java.util.regex.Pattern;

/**
 * Réduit les risques XSS en supprimant balises HTML et caractères de contrôle.
 */
public final class InputSanitizer {

    private static final Pattern HTML_TAGS = Pattern.compile("<[^>]*>", Pattern.CASE_INSENSITIVE);
    private static final Pattern SCRIPT_FRAGMENTS = Pattern.compile(
            "(?i)javascript:|data:text/html|on\\w+\\s*=");

    private InputSanitizer() {
    }

    public static String sanitizeText(String input) {
        if (input == null) {
            return null;
        }
        String trimmed = input.trim();
        if (trimmed.isEmpty()) {
            return trimmed;
        }
        String noTags = HTML_TAGS.matcher(trimmed).replaceAll("");
        noTags = SCRIPT_FRAGMENTS.matcher(noTags).replaceAll("");
        noTags = noTags.replace('\0', ' ');
        if (noTags.length() > 5000) {
            noTags = noTags.substring(0, 5000);
        }
        return noTags.trim();
    }

    public static String sanitizeEmail(String email) {
        if (email == null) {
            return null;
        }
        String e = email.trim().toLowerCase();
        if (!e.matches("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$") || e.length() > 254) {
            throw new IllegalArgumentException("Email invalide");
        }
        return e;
    }

    public static String sanitizeName(String name) {
        String s = sanitizeText(name);
        if (s == null || s.isBlank()) {
            throw new IllegalArgumentException("Nom invalide");
        }
        if (!s.matches("^[\\p{L}\\p{M}0-9 .'-]{1,100}$")) {
            throw new IllegalArgumentException("Nom invalide");
        }
        return s;
    }
}
