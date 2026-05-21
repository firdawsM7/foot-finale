package com.club.dto;

import com.club.model.Document;
import com.club.model.TypeDocument;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DocumentResponse {

    private Long id;
    private TypeDocument documentType;
    private String documentLabel;
    private String fileName;
    /** Extension fichier (pdf, jpg, …) */
    private String fileType;
    /** PDF ou IMAGE pour affichage */
    private String fileCategory;
    private Long fileSize;
    private DocumentPresentationStatus status;
    private Boolean isRequired;
    /** true si le document dépend d'une condition (ex. mineur) */
    private Boolean isConditional;
    private LocalDateTime uploadedAt;
    private String rejectionReason;

    public static DocumentResponse fromEntity(Document document, String label) {
        return DocumentResponse.builder()
                .id(document.getId())
                .documentType(document.getDocumentType())
                .documentLabel(label)
                .fileName(document.getFileName())
                .fileType(document.getFileType())
                .fileCategory(document.getFileCategory())
                .fileSize(document.getFileSize())
                .status(toPresentation(document.getStatus()))
                .isRequired(document.getIsRequired())
                .isConditional(false)
                .uploadedAt(document.getUploadedAt())
                .rejectionReason(document.getRejectionReason())
                .build();
    }

    public static DocumentResponse fromEntity(Document document, String label, boolean conditional) {
        DocumentResponse r = fromEntity(document, label);
        r.setIsConditional(conditional);
        return r;
    }

    public static DocumentPresentationStatus toPresentation(Document.DocumentStatus s) {
        if (s == null) {
            return DocumentPresentationStatus.MISSING;
        }
        return switch (s) {
            case PENDING -> DocumentPresentationStatus.PENDING;
            case APPROVED -> DocumentPresentationStatus.APPROVED;
            case REJECTED -> DocumentPresentationStatus.REJECTED;
        };
    }
}
