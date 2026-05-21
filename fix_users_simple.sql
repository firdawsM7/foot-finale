USE clubdb;

-- Nettoyage des anciens enregistrements corrompus
DELETE FROM users WHERE email IN ('admin@club.com', 'member@club.com');

-- Réinsertion avec le format qui fonctionne pour les coachs
INSERT INTO users (email, password, nom, prenom, role, actif, telephone, adresse, date_inscription) VALUES
('admin@club.com', 'password', 'Admin', 'System', 'ADMIN', true, '0600000001', '1 Rue du Club', '2024-01-01 00:00:00'),
('member@club.com', 'password', 'Martin', 'Pierre', 'ADHERENT', true, '0600000003', '3 Avenue du Sport', '2024-01-01 00:00:00');
