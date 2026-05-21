-- Fix Admin User Activation Issue
-- This script updates the admin user to have ACTIF status

-- Update admin user to be fully activated
UPDATE users 
SET 
    account_status = 'ACTIF',
    actif = TRUE
WHERE email = 'admin@club.com';

-- Also update other default users
UPDATE users 
SET 
    account_status = 'ACTIF',
    actif = TRUE
WHERE email IN ('coach@club.com', 'member@club.com');

-- Verify the changes
SELECT 
    id,
    email,
    role,
    account_status,
    actif
FROM users
WHERE email IN ('admin@club.com', 'coach@club.com', 'member@club.com');
