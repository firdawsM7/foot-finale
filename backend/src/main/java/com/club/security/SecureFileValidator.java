package com.club.security;

import org.springframework.web.multipart.MultipartFile;

import java.util.Locale;
import java.util.Set;

public final class SecureFileValidator {

    private SecureFileValidator() {
    }

    public static void validateImageUpload(MultipartFile file, long maxBytes) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Fichier vide");
        }
        if (file.getSize() > maxBytes) {
            throw new IllegalArgumentException("Fichier trop volumineux");
        }
        String ext = extension(file.getOriginalFilename());
        if (!Set.of("jpg", "jpeg", "png", "gif", "webp").contains(ext)) {
            throw new IllegalArgumentException("Type de fichier non autorisé");
        }
        String contentType = file.getContentType();
        if (contentType != null && !contentType.toLowerCase(Locale.ROOT).startsWith("image/")) {
            throw new IllegalArgumentException("Type MIME non autorisé");
        }
    }

    public static String safeStoredFileName(String extension) {
        String ext = extension.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]", "");
        if (ext.isBlank()) {
            throw new IllegalArgumentException("Extension invalide");
        }
        return java.util.UUID.randomUUID() + "." + ext;
    }

    public static String extension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return "";
        }
        return filename.substring(filename.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT);
    }
}
