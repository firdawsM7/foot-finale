package com.club.model;

public enum TypeDocument {
    // JOUEUR (Player) documents
    CIN_OR_BIRTH_CERTIFICATE,    // CIN ou Acte de naissance
    IDENTITY_PHOTO,              // Photo d'identité
    MEDICAL_CERTIFICATE,         // Certificat médical d'aptitude sportive
    FEDERAL_LICENSE,             // Licence fédérale FRMF
    REGISTRATION_FORM,           // Fiche d'inscription club
    PARENTAL_AUTHORIZATION,      // Autorisation parentale (si mineur)
    PROOF_OF_ADDRESS,            // Justificatif de domicile
    
    // ENCADRANT (Coach/Staff) documents
    CIN,                         // CIN
    SPORT_DIPLOMA,               // Diplôme sportif CAF/UEFA/FRMF
    CV,                          // CV sportif
    CRIMINAL_RECORD,             // Casier judiciaire vierge
    CONTRACT,                    // Contrat ou convention avec le club
    FEDERAL_LICENSE_COACH,       // Licence fédérale encadrant FRMF
    
    // ADHÉRENT (Member) documents
    MEMBERSHIP_FORM,             // Fiche d'adhésion
    PAYMENT_PROOF                // Justificatif de paiement cotisation
}
