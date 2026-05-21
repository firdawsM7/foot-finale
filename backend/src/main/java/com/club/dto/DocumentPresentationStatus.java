package com.club.dto;

/**
 * Display status for a document slot (includes missing uploads).
 */
public enum DocumentPresentationStatus {
    MISSING,
    PENDING,
    APPROVED,
    REJECTED
}