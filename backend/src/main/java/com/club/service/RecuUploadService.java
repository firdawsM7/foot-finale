package com.club.service;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Service
public class RecuUploadService {

    private final Path recuStorageLocation;
    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
    private static final List<String> ALLOWED_EXTENSIONS = Arrays.asList("jpg", "jpeg", "png");

    public RecuUploadService() {
        this.recuStorageLocation = Paths.get("uploads/recus").toAbsolutePath().normalize();

        try {
            Files.createDirectories(this.recuStorageLocation);
        } catch (Exception ex) {
            throw new RuntimeException("Impossible de créer le dossier de stockage des reçus.", ex);
        }
    }

    public String storeRecu(MultipartFile file) {
        // Validation de la taille
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new RuntimeException("Le fichier est trop volumineux. Taille maximale : 5MB");
        }

        // Validation de l'extension
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null) {
            throw new RuntimeException("Nom de fichier invalide");
        }

        String extension = getFileExtension(originalFilename).toLowerCase();
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new RuntimeException("Format de fichier non autorisé. Formats acceptés : JPG, PNG");
        }

        // Génération d'un nom unique
        String fileName = UUID.randomUUID().toString() + "." + extension;

        try {
            if (fileName.contains("..")) {
                throw new RuntimeException("Nom de fichier invalide " + fileName);
            }

            Path targetLocation = this.recuStorageLocation.resolve(fileName);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);

            return fileName;
        } catch (IOException ex) {
            throw new RuntimeException("Impossible de stocker le fichier " + fileName, ex);
        }
    }

    private String getFileExtension(String filename) {
        int lastDotIndex = filename.lastIndexOf('.');
        if (lastDotIndex == -1) {
            return "";
        }
        return filename.substring(lastDotIndex + 1);
    }
}
