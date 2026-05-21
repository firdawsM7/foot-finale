package com.club.dto;

import com.club.model.Document;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

public class DocumentDTO {
    private Long id;
    private String nom;
    private String type;
    private String url;
    private LocalDate dateExpiration;
    private boolean valide;
    private Long userId;
    private String userNom;
    private String userPrenom;
    private LocalDateTime uploadDate;
    private String uploadedBy;
    private long joursRestants;

    public DocumentDTO() {
    }

    public DocumentDTO(Long id, String nom, String type, String url, LocalDate dateExpiration, boolean valide,
            Long userId, String userNom, String userPrenom, LocalDateTime uploadDate, String uploadedBy,
            long joursRestants) {
        this.id = id;
        this.nom = nom;
        this.type = type;
        this.url = url;
        this.dateExpiration = dateExpiration;
        this.valide = valide;
        this.userId = userId;
        this.userNom = userNom;
        this.userPrenom = userPrenom;
        this.uploadDate = uploadDate;
        this.uploadedBy = uploadedBy;
        this.joursRestants = joursRestants;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public LocalDate getDateExpiration() {
        return dateExpiration;
    }

    public void setDateExpiration(LocalDate dateExpiration) {
        this.dateExpiration = dateExpiration;
    }

    public boolean isValide() {
        return valide;
    }

    public void setValide(boolean valide) {
        this.valide = valide;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getUserNom() {
        return userNom;
    }

    public void setUserNom(String userNom) {
        this.userNom = userNom;
    }

    public String getUserPrenom() {
        return userPrenom;
    }

    public void setUserPrenom(String userPrenom) {
        this.userPrenom = userPrenom;
    }

    public LocalDateTime getUploadDate() {
        return uploadDate;
    }

    public void setUploadDate(LocalDateTime uploadDate) {
        this.uploadDate = uploadDate;
    }

    public String getUploadedBy() {
        return uploadedBy;
    }

    public void setUploadedBy(String uploadedBy) {
        this.uploadedBy = uploadedBy;
    }

    public long getJoursRestants() {
        return joursRestants;
    }

    public void setJoursRestants(long joursRestants) {
        this.joursRestants = joursRestants;
    }

    public static DocumentDTO fromEntity(Document document) {
        DocumentDTO dto = new DocumentDTO();
        dto.setId(document.getId());
        dto.setNom(document.getFileName());
        dto.setType(document.getDocumentType().name());
        dto.setUrl(document.getFilePath());
        dto.setDateExpiration(null); // Removed from new structure
        dto.setValide(document.getStatus() == Document.DocumentStatus.APPROVED);
        dto.setUserId(document.getUser().getId());
        dto.setUserNom(document.getUser().getNom());
        dto.setUserPrenom(document.getUser().getPrenom());
        dto.setUploadDate(document.getUploadedAt());
        dto.setUploadedBy("System"); // Removed from new structure
        dto.setJoursRestants(0); // Removed from new structure
        return dto;
    }
}
