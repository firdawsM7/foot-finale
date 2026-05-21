package com.club.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Configuration entity that defines which documents are required for each user role
 */
@Entity
@Table(name = "document_type_config", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"role", "document_type"})
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DocumentTypeConfig {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private User.Role role;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "document_type", nullable = false)
    private TypeDocument documentType;
    
    @Column(name = "is_required", nullable = false)
    private Boolean isRequired;
    
    @Column(name = "document_label", nullable = false)
    private String documentLabel; // Human-readable label
    
    @Column(name = "allowed_file_types", nullable = false)
    private String allowedFileTypes; // Comma-separated: PDF,JPG,PNG
    
    @Column(name = "is_conditional")
    private Boolean isConditional = false; // e.g., parental authorization for minors
    
    @Column(name = "condition_description")
    private String conditionDescription; // e.g., "Required if age < 18"
}
