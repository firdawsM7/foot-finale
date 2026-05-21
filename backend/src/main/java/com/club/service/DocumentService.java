package com.club.service;

import com.club.dto.DocumentPresentationStatus;
import com.club.dto.DocumentResponse;
import com.club.exception.FileSizeExceededException;
import com.club.exception.InvalidDocumentTypeException;
import com.club.exception.ResourceNotFoundException;
import com.club.model.*;
import com.club.repository.DocumentRepository;
import com.club.repository.DocumentTypeConfigRepository;
import com.club.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class DocumentService {

    private final DocumentRepository documentRepository;
    private final DocumentTypeConfigRepository configRepository;
    private final UserRepository userRepository;

    @Value("${app.upload.dir:./uploads}")
    private String uploadDir;

    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024;
    private static final Set<String> ALLOWED_PDF = Set.of("pdf");
    private static final Set<String> ALLOWED_IMAGE = Set.of("jpg", "jpeg", "png");

    public DocumentService(DocumentRepository documentRepository,
                             DocumentTypeConfigRepository configRepository,
                             UserRepository userRepository) {
        this.documentRepository = documentRepository;
        this.configRepository = configRepository;
        this.userRepository = userRepository;
    }

    /**
     * Upload ou remplacement d'un document (autorisé seulement si absent, REJECTED, ou pas encore créé — pas si PENDING ou APPROVED).
     */
    public Document uploadDocument(Long userId, TypeDocument documentType, MultipartFile file, boolean forceReplace) throws IOException {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));

        validateDocumentType(user.getRole(), documentType, user.getDateNaissance());

        Optional<DocumentTypeConfig> cfgOpt = configRepository.findByRoleAndDocumentType(user.getRole(), documentType);
        DocumentTypeConfig cfg = cfgOpt.orElseThrow(() -> new InvalidDocumentTypeException(documentType.name(), user.getRole().name()));

        Optional<Document> existingOpt = documentRepository.findByUserIdAndDocumentType(userId, documentType);
        if (existingOpt.isPresent()) {
            Document ex = existingOpt.get();
            if (!forceReplace && ex.getStatus() == Document.DocumentStatus.PENDING) {
                throw new IllegalArgumentException(
                        "Ce document est en attente de validation. Vous ne pouvez pas le remplacer pour l'instant.");
            }
            if (!forceReplace && ex.getStatus() == Document.DocumentStatus.APPROVED) {
                throw new IllegalArgumentException(
                        "Ce document est déjà approuvé. Le remplacement n'est pas autorisé depuis cette interface.");
            }
        }

        validateFile(file, documentType, cfg);

        // If we are replacing, try to remove old file from disk first (best-effort).
        if (forceReplace && existingOpt.isPresent()) {
            tryDeleteFile(existingOpt.get().getFilePath());
        }

        String fileName = saveFile(userId, documentType, file);
        String ext = getFileExtension(file.getOriginalFilename()).toLowerCase();
        String category = ALLOWED_PDF.contains(ext) ? "PDF" : "IMAGE";

        Document document = existingOpt.orElseGet(() -> Document.builder()
                .user(user)
                .documentType(documentType)
                .build());

        document.setFileName(fileName);
        document.setNom(fileName);
        document.setFilePath(buildFilePath(userId, documentType, fileName));
        document.setUrl(buildFilePath(userId, documentType, fileName));
        document.setValide(false);
        document.setFileType(ext);
        document.setFileCategory(category);
        document.setFileSize(file.getSize());
        document.setUploadedAt(LocalDateTime.now());
        document.setStatus(Document.DocumentStatus.PENDING);
        document.setRejectionReason(null);
        document.setIsRequired(computeEffectiveRequired(cfg, user));

        document = documentRepository.save(document);
        updateUserRegistrationStatus(userId);
        return document;
    }

    public void deleteDocument(Long userId, Long documentId) {
        Document doc = documentRepository.findById(documentId)
                .orElseThrow(() -> new ResourceNotFoundException("Document", documentId));
        if (doc.getUser() == null || !Objects.equals(doc.getUser().getId(), userId)) {
            throw new IllegalArgumentException("Ce document n'appartient pas à cet utilisateur.");
        }
        tryDeleteFile(doc.getFilePath());
        documentRepository.delete(doc);
        updateUserRegistrationStatus(userId);
    }

    public List<Document> getDocumentsByUser(Long userId) {
        userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));
        return documentRepository.findByUserId(userId);
    }

    /**
     * Liste fusionnée : tous les emplacements requis pour le rôle + statut (MISSING si pas de fichier).
     */
    public List<DocumentResponse> getDocumentChecklistForUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));

        List<Document> documents = documentRepository.findByUserId(userId);
        Map<TypeDocument, Document> docMap = documents.stream()
                .collect(Collectors.toMap(Document::getDocumentType, d -> d, (a, b) -> a));

        List<DocumentTypeConfig> configs = configRepository.findByRole(user.getRole());
        List<DocumentResponse> out = new ArrayList<>();

        for (DocumentTypeConfig config : configs) {
            if (!configApplies(config, user)) {
                continue;
            }
            boolean required = computeEffectiveRequired(config, user);
            Document doc = docMap.get(config.getDocumentType());
            if (doc != null) {
                DocumentResponse dr = DocumentResponse.fromEntity(doc, config.getDocumentLabel(), Boolean.TRUE.equals(config.getIsConditional()));
                dr.setIsRequired(required);
                out.add(dr);
            } else {
                out.add(DocumentResponse.builder()
                        .id(null)
                        .documentType(config.getDocumentType())
                        .documentLabel(config.getDocumentLabel())
                        .fileName(null)
                        .fileType(null)
                        .fileCategory(null)
                        .fileSize(null)
                        .status(DocumentPresentationStatus.MISSING)
                        .isRequired(required)
                        .isConditional(Boolean.TRUE.equals(config.getIsConditional()))
                        .uploadedAt(null)
                        .rejectionReason(null)
                        .build());
            }
        }
        return out;
    }

    /** Ancienne API : alias vers la checklist complète */
    public List<DocumentResponse> getDocumentsResponseByUser(Long userId) {
        return getDocumentChecklistForUser(userId);
    }

    public Document validateDocument(Long documentId, Document.DocumentStatus status, String rejectionReason) {
        Document document = documentRepository.findById(documentId)
                .orElseThrow(() -> new ResourceNotFoundException("Document", documentId));

        if (status == Document.DocumentStatus.REJECTED && (rejectionReason == null || rejectionReason.trim().isEmpty())) {
            throw new IllegalArgumentException("Un motif de rejet est obligatoire lorsque le document est refusé.");
        }

        document.setStatus(status);
        document.setRejectionReason(rejectionReason);
        document = documentRepository.save(document);

        updateUserRegistrationStatus(document.getUser().getId());
        return document;
    }

    public List<DocumentResponse> getMissingDocuments(Long userId) {
        return getDocumentChecklistForUser(userId).stream()
                .filter(d -> d.getStatus() == DocumentPresentationStatus.MISSING)
                .collect(Collectors.toList());
    }

    public List<DocumentTypeConfig> getRequiredDocumentsByRole(User.Role role) {
        return configRepository.findByRole(role);
    }

    public Map<String, Object> getCompletionStatus(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));

        List<DocumentTypeConfig> configs = configRepository.findByRole(user.getRole());
        List<Document> documents = documentRepository.findByUserId(userId);
        Map<TypeDocument, Document> docMap = documents.stream()
                .collect(Collectors.toMap(Document::getDocumentType, d -> d, (a, b) -> a));

        int totalRequired = 0;
        int completed = 0;

        for (DocumentTypeConfig config : configs) {
            if (!configApplies(config, user)) {
                continue;
            }
            if (!computeEffectiveRequired(config, user)) {
                continue;
            }
            totalRequired++;
            Document doc = docMap.get(config.getDocumentType());
            if (doc != null && doc.getStatus() == Document.DocumentStatus.APPROVED) {
                completed++;
            }
        }

        int percentage = totalRequired > 0 ? (completed * 100) / totalRequired : 0;

        Map<String, Object> result = new HashMap<>();
        result.put("totalRequired", totalRequired);
        result.put("completed", completed);
        result.put("percentage", percentage);
        return result;
    }

    /**
     * Vérifie si tous les documents obligatoires sont uploadés et approuvés.
     */
    public boolean areAllMandatoryDocumentsApproved(Long userId) {
        Map<String, Object> c = getCompletionStatus(userId);
        int total = (int) c.get("totalRequired");
        int done = (int) c.get("completed");
        return total > 0 && total == done;
    }

    // --- private helpers ---

    private boolean configApplies(DocumentTypeConfig config, User user) {
        if (!Boolean.TRUE.equals(config.getIsConditional())) {
            return true;
        }
        return config.getDocumentType() == TypeDocument.PARENTAL_AUTHORIZATION && isMinor(user.getDateNaissance());
    }

    private boolean computeEffectiveRequired(DocumentTypeConfig config, User user) {
        if (!configApplies(config, user)) {
            return false;
        }
        if (Boolean.TRUE.equals(config.getIsConditional())) {
            return isMinor(user.getDateNaissance());
        }
        return Boolean.TRUE.equals(config.getIsRequired());
    }

    private void validateDocumentType(User.Role role, TypeDocument documentType, String dateNaissance) {
        DocumentTypeConfig config = configRepository.findByRoleAndDocumentType(role, documentType)
                .orElseThrow(() -> new InvalidDocumentTypeException(documentType.name(), role.name()));

        if (Boolean.TRUE.equals(config.getIsConditional()) && documentType == TypeDocument.PARENTAL_AUTHORIZATION) {
            if (!isMinor(dateNaissance)) {
                throw new InvalidDocumentTypeException(
                        "L'autorisation parentale n'est requise que pour les mineurs (< 18 ans).");
            }
        }
    }

    private void validateFile(MultipartFile file, TypeDocument documentType, DocumentTypeConfig cfg) {
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new FileSizeExceededException(file.getSize());
        }

        String extension = getFileExtension(file.getOriginalFilename()).toLowerCase();
        if (extension.isEmpty()) {
            throw new IllegalArgumentException("Extension de fichier manquante.");
        }

        if (documentType == TypeDocument.IDENTITY_PHOTO) {
            if (!ALLOWED_IMAGE.contains(extension)) {
                throw new IllegalArgumentException("La photo d'identité doit être une image (JPG ou PNG), pas un PDF.");
            }
            return;
        }

        Set<String> allowed = parseAllowedExtensions(cfg.getAllowedFileTypes());
        if (!allowed.contains(extension)) {
            throw new IllegalArgumentException(
                    "Type de fichier non autorisé pour ce document. Autorisé : " + cfg.getAllowedFileTypes());
        }
    }

    private Set<String> parseAllowedExtensions(String allowedCsv) {
        if (allowedCsv == null || allowedCsv.isBlank()) {
            Set<String> all = new HashSet<>();
            all.addAll(ALLOWED_PDF);
            all.addAll(ALLOWED_IMAGE);
            return all;
        }
        return Arrays.stream(allowedCsv.split(","))
                .map(String::trim)
                .map(String::toLowerCase)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toSet());
    }

    private String saveFile(Long userId, TypeDocument documentType, MultipartFile file) throws IOException {
        // Use absolute path based on user.dir (project root)
        String baseDir = System.getProperty("user.dir");
        Path uploadPath = Paths.get(baseDir, uploadDir.startsWith("./") ? uploadDir.substring(2) : uploadDir);
        
        Path userDir = uploadPath.resolve(userId.toString()).resolve(documentType.name());
        Files.createDirectories(userDir);

        String original = file.getOriginalFilename();
        String safeName = original != null ? original.replaceAll("[^a-zA-Z0-9._-]", "_") : "file";
        String fileName = System.currentTimeMillis() + "_" + safeName;
        Path filePath = userDir.resolve(fileName);
        file.transferTo(filePath.toFile());
        return fileName;
    }

    private String buildFilePath(Long userId, TypeDocument documentType, String fileName) {
        String baseDir = System.getProperty("user.dir");
        Path uploadPath = Paths.get(baseDir, uploadDir.startsWith("./") ? uploadDir.substring(2) : uploadDir);
        return uploadPath.resolve(userId.toString()).resolve(documentType.name()).resolve(fileName).toString();
    }

    private void tryDeleteFile(String pathStr) {
        if (pathStr == null || pathStr.isBlank()) return;
        try {
            Path p = Paths.get(pathStr);
            Files.deleteIfExists(p);
        } catch (Exception ignored) {
            // best-effort delete; keep DB consistent even if file delete fails
        }
    }

    private String getFileExtension(String fileName) {
        if (fileName == null || !fileName.contains(".")) {
            return "";
        }
        return fileName.substring(fileName.lastIndexOf(".") + 1);
    }

    private boolean isMinor(String dateNaissance) {
        if (dateNaissance == null || dateNaissance.isEmpty()) {
            return false;
        }
        try {
            LocalDate birthDate = LocalDate.parse(dateNaissance);
            return Period.between(birthDate, LocalDate.now()).getYears() < 18;
        } catch (Exception e) {
            return false;
        }
    }

    private void updateUserRegistrationStatus(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));

        if (user.getRegistrationStatus() == RegistrationStatus.REJECTED) {
            return;
        }

        Map<String, Object> completion = getCompletionStatus(userId);
        int percentage = (int) completion.get("percentage");

        if (percentage == 100) {
            user.setRegistrationStatus(RegistrationStatus.ACTIVE);
            user.setActif(true);
            user.setAccountStatus(User.AccountStatus.ACTIF);
        } else {
            user.setRegistrationStatus(RegistrationStatus.PENDING);
        }

        userRepository.save(user);
    }
}
