package com.club.repository;

import com.club.model.Document;
import com.club.model.TypeDocument;
import com.club.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DocumentRepository extends JpaRepository<Document, Long> {
    List<Document> findByUser(User user);

    List<Document> findByDocumentType(TypeDocument documentType);

    List<Document> findByUserAndDocumentType(User user, TypeDocument documentType);
    
    Optional<Document> findByUserIdAndDocumentType(Long userId, TypeDocument documentType);
    
    List<Document> findByUserIdAndStatus(Long userId, Document.DocumentStatus status);
    
    List<Document> findByUserId(Long userId);
}
