package com.club.exception;

/**
 * Erreur métier avec un message sûr pour le client.
 */
public class BusinessException extends RuntimeException {

    public BusinessException(String safeMessage) {
        super(safeMessage);
    }
}
