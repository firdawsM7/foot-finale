package com.club.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<Map<String, String>> handleBusiness(BusinessException ex) {
        log.debug("Erreur métier: {}", ex.getMessage());
        return ResponseEntity.badRequest()
                .body(Map.of("error", SafeErrorMessages.sanitizeBusinessMessage(ex.getMessage())));
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleNotFound(ResourceNotFoundException ex) {
        log.debug("Ressource introuvable: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", SafeErrorMessages.NOT_FOUND));
    }

    @ExceptionHandler({
            InvalidDocumentTypeException.class,
            FileSizeExceededException.class
    })
    public ResponseEntity<Map<String, String>> handleBadRequest(RuntimeException ex) {
        log.debug("Requête invalide: {}", ex.getMessage());
        return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.INVALID_REQUEST));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleIllegalArgument(IllegalArgumentException ex) {
        log.debug("Argument invalide: {}", ex.getMessage());
        return ResponseEntity.badRequest().body(Map.of("error", SafeErrorMessages.INVALID_REQUEST));
    }

    @ExceptionHandler({AuthenticationException.class, AccessDeniedException.class})
    public ResponseEntity<Map<String, String>> handleSecurity(Exception ex) {
        log.warn("Accès refusé: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("error", SafeErrorMessages.ACCESS_DENIED));
    }

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<Map<String, String>> handleDataAccess(DataAccessException ex) {
        log.error("Erreur base de données", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", SafeErrorMessages.GENERIC));
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, String>> handleRuntime(RuntimeException ex) {
        if (ex.getMessage() != null && isSafeUserMessage(ex.getMessage())) {
            return ResponseEntity.badRequest().body(Map.of("error", ex.getMessage()));
        }
        log.error("Erreur applicative", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", SafeErrorMessages.GENERIC));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneric(Exception ex) {
        log.error("Erreur inattendue", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", SafeErrorMessages.GENERIC));
    }

    /** Messages métier français courts, sans détails techniques. */
    private boolean isSafeUserMessage(String message) {
        if (message.length() > 120) {
            return false;
        }
        String lower = message.toLowerCase();
        return !lower.contains("sql")
                && !lower.contains("hibernate")
                && !lower.contains("exception")
                && !lower.contains("jdbc")
                && !lower.contains("column")
                && !lower.contains("table")
                && !lower.contains("syntax")
                && !lower.contains("org.")
                && !lower.contains("com.");
    }
}
