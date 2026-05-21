package com.club.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class InvalidDocumentTypeException extends RuntimeException {
    
    public InvalidDocumentTypeException(String message) {
        super(message);
    }
    
    public InvalidDocumentTypeException(String documentType, String userRole) {
        super(String.format("Document type '%s' is not valid for user role '%s'", documentType, userRole));
    }
}
