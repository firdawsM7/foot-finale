-- Migration Script: Add Account Activation System
-- This script adds support for first-time login activation
-- Run this script to update existing database schema

-- Step 1: Add new columns for account activation
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS account_status ENUM('ACTIF', 'ACTIVATION_REQUISE', 'SUSPENDU') DEFAULT 'ACTIVATION_REQUISE',
ADD COLUMN IF NOT EXISTS activation_token VARCHAR(255) UNIQUE;

-- Step 2: Update existing users to be activated (since they already have passwords)
UPDATE users 
SET 
    account_status = 'ACTIF',
    actif = TRUE
WHERE password IS NOT NULL AND password != '';

-- Step 3: Make password column nullable for new admin-created users
ALTER TABLE users 
MODIFY COLUMN password VARCHAR(255) NULL;

-- Step 4: Set default value for actif to FALSE
ALTER TABLE users 
MODIFY COLUMN actif BOOLEAN DEFAULT FALSE;

-- Step 5: Generate activation tokens for any users that might need them (optional)
-- Uncomment if you want to create tokens for specific users
-- UPDATE users 
-- SET activation_token = UUID()
-- WHERE account_status = 'ACTIVATION_REQUISE' AND activation_token IS NULL;

-- Verification query
SELECT 
    id,
    email,
    nom,
    prenom,
    role,
    account_status,
    activation_token,
    actif,
    CASE 
        WHEN password IS NULL THEN 'NO PASSWORD'
        WHEN password LIKE '$2a$%' OR password LIKE '$2b$%' THEN 'HASHED'
        ELSE 'PLAIN TEXT (needs migration)'
    END as password_status
FROM users
ORDER BY id;
