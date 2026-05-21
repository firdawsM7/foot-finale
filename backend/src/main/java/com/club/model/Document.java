package com.club.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "documents")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Document {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "document_type", nullable = false)
    private TypeDocument documentType;

    @Column(name = "file_name", nullable = false)
    private String fileName;

    @Column(name = "file_path", nullable = false)
    private String filePath;

    @Column(name = "file_type", nullable = false)
    private String fileType; // extension: pdf, jpg, png

    /** PDF ou IMAGE (règles métier : photo d'identité = IMAGE uniquement) */
    @Column(name = "file_category", nullable = true)
    private String fileCategory;

    @Column(name = "file_size")
    private Long fileSize; // in bytes

    @Column(name = "nom", nullable = false)
    private String nom;

    @Column(name = "url", nullable = false)
    private String url;

    @Column(name = "is_required", nullable = false)
    private Boolean isRequired = true;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private DocumentStatus status = DocumentStatus.PENDING;

    @Column(name = "rejection_reason")
    private String rejectionReason;

    @Column(name = "uploaded_at", nullable = false)
    private LocalDateTime uploadedAt;

    @Column(name = "valide", nullable = false)
    private Boolean valide = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public Boolean getValide() {
        return valide;
    }

    public void setValide(Boolean valide) {
        this.valide = valide;
    }

    public enum DocumentStatus {
        PENDING,    // En attente de validation
        APPROVED,   // Approuvé
        REJECTED    // Rejeté
    }
}
