USE clubdb;

DELETE FROM users WHERE email IN ('admin@club.com', 'member@club.com');

INSERT INTO users (actif, adresse, date_inscription, date_naissance, email, nom, password, prenom, role, telephone) VALUES 
(1, '1 Rue du Club', '2024-01-01 00:00:00', NULL, 'admin@club.com', 'Admin', '$2a$10$8.UnVuG9HHgffUDAlk8Kn.2Nv5EInT.6vyL.XoM7p.1S0p9L.5E1a', 'System', 'ADMIN', '0600000001'),
(1, '3 Avenue du Sport', '2024-01-01 00:00:00', NULL, 'member@club.com', 'Martin', '$2a$10$8.UnVuG9HHgffUDAlk8Kn.2Nv5EInT.6vyL.XoM7p.1S0p9L.5E1a', 'Pierre', 'ADHERENT', '0600000003');
