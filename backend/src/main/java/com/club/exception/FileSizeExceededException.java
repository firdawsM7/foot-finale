package com.club.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class FileSizeExceededException extends RuntimeException {
    
    private static final long MAX_SIZE = 5 * 1024 * 1024; // 5MB
    
    public FileSizeExceededException(String message) {
        super(message);
    }
    
    public FileSizeExceededException(long fileSize) {
        super(String.format("File size (%.2f MB) exceeds maximum allowed size (%.2f MB)", 
            fileSize / (1024.0 * 1024.0), 
            MAX_SIZE / (1024.0 * 1024.0)));
    }
}
