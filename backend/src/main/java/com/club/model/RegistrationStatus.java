package com.club.model;

/**
 * User registration workflow status (admin dossier).
 */
public enum RegistrationStatus {
    /** Incomplete dossier or validation in progress */
    PENDING,
    /** All mandatory documents uploaded and approved */
    ACTIVE,
    /** Rejected by administrator */
    REJECTED
}