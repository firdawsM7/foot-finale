-- ============================================
-- MAS Fès Club - Document Management System
-- Database Migration Script
-- ============================================

-- Step 1: Add new column to users table for document status
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS document_status ENUM('PENDING', 'COMPLETE', 'INCOMPLETE') DEFAULT 'PENDING';

-- Step 2: Drop old documents table and recreate with new schema
DROP TABLE IF EXISTS documents;

CREATE TABLE documents (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    document_type VARCHAR(50) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(10) NOT NULL,
    file_size BIGINT,
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    status ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
    rejection_reason TEXT,
    uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id BIGINT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_document_type (document_type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Step 3: Create document_type_config table
CREATE TABLE document_type_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role VARCHAR(50) NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    document_label VARCHAR(255) NOT NULL,
    allowed_file_types VARCHAR(100) NOT NULL,
    is_conditional BOOLEAN DEFAULT FALSE,
    condition_description VARCHAR(500),
    UNIQUE KEY unique_role_document (role, document_type),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Step 4: Insert document configuration for JOUEUR (Player)
INSERT INTO document_type_config (role, document_type, is_required, document_label, allowed_file_types, is_conditional, condition_description) VALUES
('JOUEUR', 'CIN_OR_BIRTH_CERTIFICATE', TRUE, 'CIN ou Acte de naissance', 'PDF,JPG,PNG', FALSE, NULL),
('JOUEUR', 'IDENTITY_PHOTO', TRUE, 'Photo d''identité', 'JPG,PNG', FALSE, NULL),
('JOUEUR', 'MEDICAL_CERTIFICATE', TRUE, 'Certificat médical d''aptitude sportive (< 3 mois)', 'PDF', FALSE, NULL),
('JOUEUR', 'FEDERAL_LICENSE', TRUE, 'Licence fédérale FRMF', 'PDF', FALSE, NULL),
('JOUEUR', 'REGISTRATION_FORM', TRUE, 'Fiche d''inscription club', 'PDF', FALSE, NULL),
('JOUEUR', 'PROOF_OF_ADDRESS', TRUE, 'Justificatif de domicile', 'PDF,JPG,PNG', FALSE, NULL),
('JOUEUR', 'PARENTAL_AUTHORIZATION', TRUE, 'Autorisation parentale (si mineur)', 'PDF', TRUE, 'Required if age < 18');

-- Step 5: Insert document configuration for ENCADRANT (Coach/Staff)
INSERT INTO document_type_config (role, document_type, is_required, document_label, allowed_file_types, is_conditional, condition_description) VALUES
('ENCADRANT', 'CIN', TRUE, 'CIN', 'PDF,JPG,PNG', FALSE, NULL),
('ENCADRANT', 'IDENTITY_PHOTO', TRUE, 'Photo d''identité', 'JPG,PNG', FALSE, NULL),
('ENCADRANT', 'SPORT_DIPLOMA', TRUE, 'Diplôme sportif CAF/UEFA/FRMF', 'PDF', FALSE, NULL),
('ENCADRANT', 'CV', TRUE, 'CV sportif', 'PDF', FALSE, NULL),
('ENCADRANT', 'CRIMINAL_RECORD', TRUE, 'Casier judiciaire vierge', 'PDF', FALSE, NULL),
('ENCADRANT', 'CONTRACT', TRUE, 'Contrat ou convention avec le club', 'PDF', FALSE, NULL),
('ENCADRANT', 'FEDERAL_LICENSE_COACH', TRUE, 'Licence fédérale encadrant FRMF', 'PDF', FALSE, NULL);

-- Step 6: Insert document configuration for ADHÉRENT (Member)
INSERT INTO document_type_config (role, document_type, is_required, document_label, allowed_file_types, is_conditional, condition_description) VALUES
('ADHERENT', 'CIN_OR_BIRTH_CERTIFICATE', TRUE, 'CIN ou Acte de naissance', 'PDF,JPG,PNG', FALSE, NULL),
('ADHERENT', 'IDENTITY_PHOTO', TRUE, 'Photo d''identité', 'JPG,PNG', FALSE, NULL),
('ADHERENT', 'MEMBERSHIP_FORM', TRUE, 'Fiche d''adhésion', 'PDF', FALSE, NULL),
('ADHERENT', 'PAYMENT_PROOF', TRUE, 'Justificatif de paiement cotisation', 'PDF,JPG,PNG', FALSE, NULL),
('ADHERENT', 'PARENTAL_AUTHORIZATION', TRUE, 'Autorisation parentale (si mineur)', 'PDF', TRUE, 'Required if age < 18');

-- Step 7: Create upload directories (this is handled by the application, not SQL)
-- The application will create: ./uploads/{userId}/{documentType}/

-- Verification queries
SELECT 'Users table structure:' AS Info;
DESCRIBE users;

SELECT 'Documents table structure:' AS Info;
DESCRIBE documents;

SELECT 'Document type config table structure:' AS Info;
DESCRIBE document_type_config;

SELECT 'Document configuration for JOUEUR:' AS Info;
SELECT document_type, document_label, is_required, is_conditional, condition_description 
FROM document_type_config 
WHERE role = 'JOUEUR' 
ORDER BY is_required DESC, document_type;

SELECT 'Document configuration for ENCADRANT:' AS Info;
SELECT document_type, document_label, is_required, is_conditional, condition_description 
FROM document_type_config 
WHERE role = 'ENCADRANT' 
ORDER BY is_required DESC, document_type;

SELECT 'Document configuration for ADHERENT:' AS Info;
SELECT document_type, document_label, is_required, is_conditional, condition_description 
FROM document_type_config 
WHERE role = 'ADHERENT' 
ORDER BY is_required DESC, document_type;

SELECT 'Migration completed successfully!' AS Status;
