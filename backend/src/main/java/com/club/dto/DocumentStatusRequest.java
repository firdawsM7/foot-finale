package com.club.dto;

import com.club.model.Document;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentStatusRequest {
    
    private Document.DocumentStatus status;
    private String rejectionReason; // Required when status is REJECTED
}
