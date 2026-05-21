package com.club.repository;

import com.club.model.DocumentTypeConfig;
import com.club.model.TypeDocument;
import com.club.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DocumentTypeConfigRepository extends JpaRepository<DocumentTypeConfig, Long> {
    
    List<DocumentTypeConfig> findByRole(User.Role role);
    
    Optional<DocumentTypeConfig> findByRoleAndDocumentType(User.Role role, TypeDocument documentType);
    
    List<DocumentTypeConfig> findByRoleAndIsRequired(User.Role role, Boolean isRequired);
    
    List<DocumentTypeConfig> findByRoleAndIsConditional(User.Role role, Boolean isConditional);
}
