package com.club.controller;

import com.club.dto.DocumentResponse;
import com.club.dto.DocumentStatusRequest;
import com.club.model.Document;
import com.club.model.DocumentTypeConfig;
import com.club.model.TypeDocument;
import com.club.model.User;
import com.club.service.DocumentService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin")
@PreAuthorize("hasRole('ADMIN')")
public class DocumentController {
    
    private final DocumentService documentService;
    
    public DocumentController(DocumentService documentService) {
        this.documentService = documentService;
    }
    
    /**
     * Get all documents for a user
     */
    @GetMapping("/users/{userId}/documents")
    public ResponseEntity<List<DocumentResponse>> getUserDocuments(@PathVariable Long userId) {
        List<DocumentResponse> documents = documentService.getDocumentsResponseByUser(userId);
        return ResponseEntity.ok(documents);
    }
    
    /**
     * Upload a document for a user
     */
    @PostMapping("/users/{userId}/documents")
    public ResponseEntity<DocumentResponse> uploadDocument(
            @PathVariable Long userId,
            @RequestParam("documentType") TypeDocument documentType,
            @RequestParam("file") MultipartFile file,
            @RequestParam(name = "force", defaultValue = "false") boolean force) throws IOException {
        
        Document document = documentService.uploadDocument(userId, documentType, file, force);
        // Return a DTO to avoid serializing Hibernate proxies (user relation is lazy).
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(DocumentResponse.fromEntity(document, documentType.name()));
    }

    /**
     * Delete a document for a user (and remove file from disk).
     */
    @DeleteMapping("/users/{userId}/documents/{documentId}")
    public ResponseEntity<?> deleteDocument(
            @PathVariable Long userId,
            @PathVariable Long documentId) {
        documentService.deleteDocument(userId, documentId);
        return ResponseEntity.noContent().build();
    }
    
    /**
     * Get missing documents for a user
     */
    @GetMapping("/users/{userId}/documents/missing")
    public ResponseEntity<List<DocumentResponse>> getMissingDocuments(@PathVariable Long userId) {
        List<DocumentResponse> missingDocs = documentService.getMissingDocuments(userId);
        return ResponseEntity.ok(missingDocs);
    }
    
    /**
     * Update document status (approve/reject)
     */
    @PutMapping("/documents/{documentId}/status")
    public ResponseEntity<DocumentResponse> updateDocumentStatus(
            @PathVariable Long documentId,
            @RequestBody DocumentStatusRequest request) {
        
        Document document = documentService.validateDocument(
                documentId, 
                request.getStatus(), 
                request.getRejectionReason()
        );
        return ResponseEntity.ok(DocumentResponse.fromEntity(document, document.getDocumentType().name()));
    }
    
    /**
     * Get required documents configuration for a role
     */
    @GetMapping("/document-config/{role}")
    public ResponseEntity<List<DocumentTypeConfig>> getDocumentConfig(@PathVariable User.Role role) {
        List<DocumentTypeConfig> configs = documentService.getRequiredDocumentsByRole(role);
        return ResponseEntity.ok(configs);
    }
    
    /**
     * Get completion status for a user
     */
    @GetMapping("/users/{userId}/documents/completion")
    public ResponseEntity<Map<String, Object>> getCompletionStatus(@PathVariable Long userId) {
        Map<String, Object> completion = documentService.getCompletionStatus(userId);
        return ResponseEntity.ok(completion);
    }
}
