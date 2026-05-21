-- Insert document configuration for JOUEUR (Player)
INSERT IGNORE INTO document_type_config (role, document_type, is_required, document_label, allowed_file_types, is_conditional, condition_description) VALUES
('JOUEUR', 'CIN_OR_BIRTH_CERTIFICATE', TRUE, 'CIN ou Acte de naissance', 'PDF,JPG,PNG', FALSE, NULL),
('JOUEUR', 'IDENTITY_PHOTO', TRUE, 'Photo d''identité', 'JPG,PNG', FALSE, NULL),
('JOUEUR', 'MEDICAL_CERTIFICATE', TRUE, 'Certificat médical d''aptitude sportive (< 3 mois)', 'PDF', FALSE, NULL),
('JOUEUR', 'FEDERAL_LICENSE', TRUE, 'Licence fédérale FRMF', 'PDF', FALSE, NULL),
('JOUEUR', 'REGISTRATION_FORM', TRUE, 'Fiche d''inscription club', 'PDF', FALSE, NULL),
('JOUEUR', 'PROOF_OF_ADDRESS', TRUE, 'Justificatif de domicile', 'PDF,JPG,PNG', FALSE, NULL),
('JOUEUR', 'PARENTAL_AUTHORIZATION', TRUE, 'Autorisation parentale (si mineur)', 'PDF', TRUE, 'Required if age < 18');

-- Insert document configuration for ENCADRANT (Coach/Staff)
INSERT IGNORE INTO document_type_config (role, document_type, is_required, document_label, allowed_file_types, is_conditional, condition_description) VALUES
('ENCADRANT', 'CIN', TRUE, 'CIN', 'PDF,JPG,PNG', FALSE, NULL),
('ENCADRANT', 'IDENTITY_PHOTO', TRUE, 'Photo d''identité', 'JPG,PNG', FALSE, NULL),
('ENCADRANT', 'SPORT_DIPLOMA', TRUE, 'Diplôme sportif CAF/UEFA/FRMF', 'PDF', FALSE, NULL),
('ENCADRANT', 'CV', TRUE, 'CV sportif', 'PDF', FALSE, NULL),
('ENCADRANT', 'CRIMINAL_RECORD', TRUE, 'Casier judiciaire vierge', 'PDF', FALSE, NULL),
('ENCADRANT', 'CONTRACT', TRUE, 'Contrat ou convention avec le club', 'PDF', FALSE, NULL),
('ENCADRANT', 'FEDERAL_LICENSE_COACH', TRUE, 'Licence fédérale encadrant FRMF', 'PDF', FALSE, NULL);

-- Insert document configuration for ADHÉRENT (Member)
INSERT IGNORE INTO document_type_config (role, document_type, is_required, document_label, allowed_file_types, is_conditional, condition_description) VALUES
('ADHERENT', 'CIN_OR_BIRTH_CERTIFICATE', TRUE, 'CIN ou Acte de naissance', 'PDF,JPG,PNG', FALSE, NULL),
('ADHERENT', 'IDENTITY_PHOTO', TRUE, 'Photo d''identité', 'JPG,PNG', FALSE, NULL),
('ADHERENT', 'MEMBERSHIP_FORM', TRUE, 'Fiche d''adhésion', 'PDF', FALSE, NULL),
('ADHERENT', 'PAYMENT_PROOF', TRUE, 'Justificatif de paiement cotisation', 'PDF,JPG,PNG', FALSE, NULL),
('ADHERENT', 'PARENTAL_AUTHORIZATION', TRUE, 'Autorisation parentale (si mineur)', 'PDF', TRUE, 'Required if age < 18');

SELECT 'Document configuration inserted successfully!' AS Status;
SELECT COUNT(*) as total_configs FROM document_type_config;
