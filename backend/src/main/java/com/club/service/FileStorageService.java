package com.club.service;

import com.club.security.SecureFileValidator;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
public class FileStorageService {

    private final Path fileStorageLocation;

    public FileStorageService() {
        this.fileStorageLocation = Paths.get("uploads/photos").toAbsolutePath().normalize();

        try {
            Files.createDirectories(this.fileStorageLocation);
        } catch (Exception ex) {
            throw new RuntimeException("Impossible de créer le dossier de stockage des photos.", ex);
        }
    }

    public String storeFile(MultipartFile file) {
        SecureFileValidator.validateImageUpload(file, 5 * 1024 * 1024);
        String ext = SecureFileValidator.extension(file.getOriginalFilename());
        String fileName = SecureFileValidator.safeStoredFileName(ext);

        try {
            Path targetLocation = this.fileStorageLocation.resolve(fileName).normalize();
            if (!targetLocation.startsWith(this.fileStorageLocation)) {
                throw new RuntimeException("Chemin de fichier invalide");
            }
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);

            return fileName;
        } catch (IOException ex) {
            throw new RuntimeException("Impossible de stocker le fichier " + fileName, ex);
        }
    }
}
