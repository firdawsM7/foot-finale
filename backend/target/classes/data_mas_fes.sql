-- DATA GENERATION FOR MAS DE FÈS (Maghreb Association Sportive de Fès)
-- Season 2024-2025

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE injury_suspensions;
TRUNCATE TABLE player_technical_notes;
TRUNCATE TABLE cotisations;
TRUNCATE TABLE entrainements;
TRUNCATE TABLE matchs;
TRUNCATE TABLE joueurs;
TRUNCATE TABLE equipes;
TRUNCATE TABLE users;
SET FOREIGN_KEY_CHECKS = 1;


-- 1. STAFF TECHNIQUE (Role: ENCADRANT)
INSERT INTO users (email, password, nom, prenom, role, actif, telephone, adresse, date_inscription) VALUES
('coach.gamondi@mas.ma', 'password', 'Gamondi', 'Miguel Angel', 'ENCADRANT', true, '0661223344', 'Résidence Al Ismailia, Fès', '2024-06-15 10:00:00'),
('adjoint.benzekri@mas.ma', 'password', 'Benzekri', 'Khalid', 'ENCADRANT', true, '0661556677', 'Quartier Narjis, Fès', '2024-06-15 10:30:00'),
('physique.moughit@mas.ma', 'password', 'Moughit', 'Hamza', 'ENCADRANT', true, '0661889900', 'Quartier Atlas, Fès', '2024-07-01 09:00:00'),
('medecin.fassi@mas.ma', 'password', 'Fassi-Fihri', 'Driss', 'ENCADRANT', true, '0661112233', 'Route d Imouzzer, Fès', '2024-07-01 11:00:00'),
('u21.coach@mas.ma', 'password', 'Lahlou', 'Mehdi', 'ENCADRANT', true, '0661445566', 'Zouagha, Fès', '2024-07-10 08:30:00'),
('u19.coach@mas.ma', 'password', 'Sbai', 'Youssef', 'ENCADRANT', true, '0661778899', 'Sidi Brahim, Fès', '2024-07-10 14:00:00'),
('kine.alami@mas.ma', 'password', 'Alami', 'Said', 'ENCADRANT', true, '0661001122', 'Bensouda, Fès', '2024-07-20 10:00:00'),
('scout.taoussi@mas.ma', 'password', 'Taoussi', 'Rachid', 'ENCADRANT', true, '0661334455', 'Ain Chkef, Fès', '2024-08-01 12:00:00'),
('futsal.coach@mas.ma', 'password', 'Amrani', 'Tarik', 'ENCADRANT', true, '0661667788', 'Oued Fès, Fès', '2024-08-15 16:00:00'),
('reserve.coach@mas.ma', 'password', 'Filali', 'Mustapha', 'ENCADRANT', true, '0661990011', 'Quartier Talaa, Fès', '2024-08-20 10:00:00'),
('admin@club.com', 'password', 'Admin', 'System', 'ADMIN', true, '0600000001', '1 Rue du Club', '2024-01-01 00:00:00'),
('member@club.com', 'password', 'Martin', 'Pierre', 'ADHERENT', true, '0600000003', '3 Avenue du Sport', '2024-01-01 00:00:00');

-- 2. ÉQUIPES (5)
INSERT INTO equipes (nom, categorie, active, description, encadrant_id) VALUES
('MAGHREB ASSOCIATION SPORTIVE - ÉQUIPE A', 'Senior A', true, 'Équipe première évoluant en Botola Pro', 1),
('MAS FÈS - RÉSERVE', 'Senior B', true, 'Équipe espoir / réserve club', 10),
('MAS FÈS - U21', 'U21', true, 'Catégorie Espoirs excellence', 5),
('MAS FÈS - U19', 'U19', true, 'Catégorie Juniors excellence', 6),
('MAS FÈS - FUTSAL', 'Futsal', true, 'Équipe de Futsal MAS', 9);

-- 3. JOUEURS (50) - ÉQUIPE A (25)
INSERT INTO joueurs (nom, prenom, date_naissance, nationalite, poste, numero_maillot, poids, taille, actif, equipe_id) VALUES
('Alioui', 'Haytam', '1995-02-14', 'Marocaine', 'Attaquant', 7, 72.5, 1.82, true, 1),
('Aguerd', 'Nayef', '1996-03-30', 'Marocaine', 'Défenseur', 5, 80.0, 1.90, true, 1),
('Amallah', 'Selim', '1996-11-15', 'Marocaine', 'Milieu', 15, 76.0, 1.85, true, 1),
('Bounou', 'Yassine', '1991-04-05', 'Marocaine', 'Gardien', 1, 82.0, 1.92, true, 1),
('Ziyech', 'Hakim', '1993-03-19', 'Marocaine', 'Ailier', 22, 70.0, 1.81, true, 1),
('En-Nesyri', 'Youssef', '1997-06-01', 'Marocaine', 'Attaquant', 19, 78.0, 1.88, true, 1),
('Saiss', 'Romain', '1990-03-26', 'Marocaine', 'Défenseur', 6, 81.0, 1.86, true, 1),
('Hakimi', 'Achraf', '1998-11-04', 'Marocaine', 'Latéral', 2, 73.0, 1.81, true, 1),
('Ounahi', 'Azzedine', '2000-04-19', 'Marocaine', 'Milieu', 8, 65.0, 1.82, true, 1),
('Boufal', 'Sofiane', '1993-09-17', 'Marocaine', 'Ailier', 17, 70.0, 1.75, true, 1),
('Traoré', 'Hamidou', '1996-08-25', 'Malienne', 'Milieu', 28, 77.0, 1.84, true, 1),
('Ndiaye', 'Papa', '1994-12-10', 'Sénégalaise', 'Défenseur', 4, 83.0, 1.88, true, 1),
('Camara', 'Mohamed', '1999-01-15', 'Guinéenne', 'Gardien', 16, 80.0, 1.85, true, 1),
('Smith', 'John', '1995-05-20', 'Anglaise', 'Attaquant', 9, 79.0, 1.83, true, 1),
('Garcia', 'Luis', '1997-10-12', 'Espagnole', 'Milieu', 10, 71.0, 1.78, true, 1),
('Rahimi', 'Soufiane', '1996-06-02', 'Marocaine', 'Attaquant', 21, 74.0, 1.80, true, 1),
('Dari', 'Achraf', '1999-05-06', 'Marocaine', 'Défenseur', 20, 84.0, 1.88, true, 1),
('Attiat-Allah', 'Yahya', '1995-03-02', 'Marocaine', 'Latéral', 25, 72.0, 1.79, true, 1),
('El Kaabi', 'Ayoub', '1993-06-25', 'Marocaine', 'Attaquant', 18, 76.0, 1.82, true, 1),
('Aboukhlal', 'Zakaria', '2000-02-18', 'Marocaine', 'Ailier', 14, 75.0, 1.79, true, 1),
('Munir', 'Mohand', '1989-05-10', 'Marocaine', 'Gardien', 12, 85.0, 1.90, true, 1),
('Jabrane', 'Yahya', '1991-06-18', 'Marocaine', 'Milieu', 3, 78.0, 1.87, true, 1),
('Chibi', 'Mohamed', '1993-01-21', 'Marocaine', 'Latéral', 13, 71.0, 1.77, true, 1),
('El Yamiq', 'Jawad', '1992-02-29', 'Marocaine', 'Défenseur', 24, 82.0, 1.90, true, 1),
('Hamdallah', 'Abderrazak', '1990-11-20', 'Marocaine', 'Attaquant', 11, 83.0, 1.82, true, 1);

-- JOUEURS - U21 (15)
INSERT INTO joueurs (nom, prenom, date_naissance, nationalite, poste, numero_maillot, poids, taille, actif, equipe_id) VALUES
('Zalami', 'Yassine', '2004-05-10', 'Marocaine', 'Milieu', 31, 68.0, 1.78, true, 3),
('Bennis', 'Omar', '2004-02-15', 'Marocaine', 'Défenseur', 32, 75.0, 1.85, true, 3),
('El Fihri', 'Anas', '2004-11-20', 'Marocaine', 'Gardien', 30, 78.0, 1.88, true, 3),
('Souiri', 'Hamza', '2004-08-05', 'Marocaine', 'Attaquant', 33, 70.0, 1.80, true, 3),
('Tazi', 'Ismail', '2005-01-12', 'Marocaine', 'Milieu', 34, 66.0, 1.75, true, 3),
('Idrissi', 'Ayoub', '2005-06-25', 'Marocaine', 'Latéral', 35, 69.0, 1.77, true, 3),
('Benani', 'Mehdi', '2004-12-30', 'Marocaine', 'Défenseur', 36, 73.0, 1.84, true, 3),
('Diallo', 'Moussa', '2004-03-22', 'Guinéenne', 'Attaquant', 37, 71.0, 1.82, true, 3),
('Kone', 'Bakary', '2005-07-14', 'Ivoirienne', 'Milieu', 38, 74.0, 1.80, true, 3),
('Dahbi', 'Walid', '2004-09-18', 'Marocaine', 'Gardien', 40, 80.0, 1.91, true, 3),
('Slaoui', 'Rachid', '2005-04-02', 'Marocaine', 'Latéral', 41, 67.0, 1.76, true, 3),
('Mernissi', 'Amine', '2004-10-10', 'Marocaine', 'Milieu', 42, 69.0, 1.79, true, 3),
('Hajji', 'Youssef', '2005-11-05', 'Marocaine', 'Attaquant', 43, 72.0, 1.81, true, 3),
('Bouanani', 'Badreddine', '2004-12-13', 'Marocaine', 'Ailier', 44, 70.0, 1.78, true, 3),
('El Amrani', 'Saad', '2005-02-28', 'Marocaine', 'Défenseur', 45, 76.0, 1.87, true, 3);

-- JOUEURS - U19 (10)
INSERT INTO joueurs (nom, prenom, date_naissance, nationalite, poste, numero_maillot, poids, taille, actif, equipe_id) VALUES
('Kamal', 'Reda', '2006-03-10', 'Marocaine', 'Milieu', 50, 64.0, 1.74, true, 4),
('Filali', 'Said', '2006-08-15', 'Marocaine', 'Défenseur', 51, 70.0, 1.82, true, 4),
('Abidi', 'Younes', '2007-02-05', 'Marocaine', 'Gardien', 49, 75.0, 1.86, true, 4),
('Zeroual', 'Tarik', '2006-11-20', 'Marocaine', 'Attaquant', 52, 68.0, 1.78, true, 4),
('Lahlou', 'Zaid', '2007-01-12', 'Marocaine', 'Milieu', 53, 62.0, 1.72, true, 4),
('Sekkat', 'Adam', '2006-05-25', 'Marocaine', 'Latéral', 54, 65.0, 1.75, true, 4),
('Alaoui', 'Driss', '2007-10-30', 'Marocaine', 'Défenseur', 55, 72.0, 1.84, true, 4),
('Moussaoui', 'Oussama', '2006-09-18', 'Marocaine', 'Attaquant', 56, 70.0, 1.81, true, 4),
('Kabbaj', 'Anas', '2007-12-05', 'Marocaine', 'Milieu', 57, 66.0, 1.76, true, 4),
('Berrada', 'Omar', '2006-04-02', 'Marocaine', 'Gardien', 58, 76.0, 1.89, true, 4);

-- 4. MATCHS (20)
INSERT INTO matchs (equipe_id, adversaire, date_heure, lieu, type, score_equipe, score_adversaire, statut, notes) VALUES
(1, 'Raja CA', '2024-09-15 19:00:00', 'Stade Père Jégo, Casablanca', 'CHAMPIONNAT', 1, 1, 'TERMINE', 'Match nul précieux à extérieur'),
(1, 'Wydad AC', '2024-09-22 17:00:00', 'Complexe Sportif de Fès', 'CHAMPIONNAT', 2, 1, 'TERMINE', 'Victoire historique devant les supporters'),
(1, 'RS Berkane', '2024-09-29 20:00:00', 'Stade Municipal de Berkane', 'CHAMPIONNAT', 0, 1, 'TERMINE', 'Défaite difficile sur un penalty'),
(1, 'AS FAR', '2024-10-06 18:30:00', 'Complexe Sportif de Fès', 'CHAMPIONNAT', 1, 1, 'TERMINE', 'Match très tactique'),
(1, 'FUS Rabat', '2024-10-13 16:00:00', 'Stade Moulay Hassan, Rabat', 'CHAMPIONNAT', 1, 0, 'TERMINE', 'Bel exploit à Rabat'),
(1, 'Moghreb Tétouan', '2024-10-20 18:00:00', 'Complexe Sportif de Fès', 'CHAMPIONNAT', 3, 0, 'TERMINE', 'Large victoire à domicile'),
(1, 'Hassania Agadir', '2024-11-03 20:00:00', 'Stade Adrar, Agadir', 'CHAMPIONNAT', 0, 0, 'TERMINE', 'Match fermé'),
(1, 'Ittihad Tanger', '2024-11-10 17:00:00', 'Complexe Sportif de Fès', 'CHAMPIONNAT', 2, 2, 'TERMINE', 'Remontée spectaculaire en fin de match'),
(1, 'Olympic Safi', '2024-11-17 19:00:00', 'Stade El Massira, Safi', 'CHAMPIONNAT', 1, 2, 'TERMINE', 'Manque de réalisme offensif'),
(1, 'SC Chabab Mohammédia', '2024-12-01 16:00:00', 'Complexe Sportif de Fès', 'CHAMPIONNAT', NULL, NULL, 'PLANIFIE', 'Prochain match important'),
(3, 'RCA U21', '2024-09-14 11:00:00', 'Académie du Raja', 'TOURNOI', 2, 0, 'TERMINE', 'Excellente prestation des jeunes'),
(3, 'WAC U21', '2024-09-21 11:30:00', 'Centre de formation MAS', 'CHAMPIONNAT', 1, 1, 'TERMINE', 'Match équilibré'),
(4, 'FUS U19', '2024-09-28 10:00:00', 'Complexe Sportif de Fès', 'CHAMPIONNAT', 3, 1, 'TERMINE', 'Bonne progression technique'),
(1, 'Union Touarga', '2024-12-08 18:00:00', 'Stade Moulay El Hassan, Rabat', 'CHAMPIONNAT', NULL, NULL, 'PLANIFIE', NULL),
(1, 'Raja CA', '2025-01-12 17:00:00', 'Complexe Sportif de Fès', 'CHAMPIONNAT', NULL, NULL, 'PLANIFIE', 'Derby retour'),
(1, 'Club Africain', '2024-08-25 20:30:00', 'Stade de Rades, Tunis', 'AMICAL', 1, 2, 'TERMINE', 'Match de préparation internationale'),
(1, 'ES Sétif', '2024-08-20 19:00:00', 'Complexe Sportif de Fès', 'AMICAL', 2, 2, 'TERMINE', 'Tests physiques réussis'),
(5, 'Chabab Settat Futsal', '2024-10-15 19:00:00', 'Salle couverte de Fès', 'CHAMPIONNAT', 5, 3, 'TERMINE', 'Belle victoire en Futsal'),
(1, 'KACM Marrakech', '2025-02-15 16:00:00', 'Stade de Marrakech', 'COUPE', NULL, NULL, 'PLANIFIE', '16ème de finale Coupe du Trône'),
(1, 'Stade Marocain', '2025-02-22 15:00:00', 'Complexe Sportif de Fès', 'COUPE', NULL, NULL, 'PLANIFIE', 'Probable qualification');

-- 5. ENTRAÎNEMENTS (100)
INSERT INTO entrainements (equipe_id, date_heure, lieu, duree, objectif, encadrant_id, statut) VALUES
(1, '2024-09-01 09:00:00', 'Annexe terrain Fès', 90, 'Reprise physique et tests VMA', 1, 'TERMINE'),
(1, '2024-09-02 09:30:00', 'Salle de gym MAS', 60, 'Renforcement musculaire haut du corps', 3, 'TERMINE'),
(1, '2024-09-03 17:00:00', 'Complexe Sportif de Fès', 100, 'Tactique : Bloc bas et transition rapide', 1, 'TERMINE'),
(1, '2024-09-04 09:00:00', 'Annexe terrain Fès', 90, 'Finitions devant le but et centres', 2, 'TERMINE'),
(1, '2024-09-05 10:00:00', 'Piscine olympique', 45, 'Récupération active et balnéo', 4, 'TERMINE'),
(3, '2024-09-01 10:30:00', 'Centre de formation', 90, 'Coordination et technique individuelle', 5, 'TERMINE'),
(4, '2024-09-01 14:00:00', 'Centre de formation', 90, 'Développement technique U19', 6, 'TERMINE'),
(1, '2024-09-07 09:00:00', 'Complexe Sportif de Fès', 90, 'Mise en place tactique avant match', 1, 'TERMINE'),
(1, '2024-09-08 10:00:00', 'Annexe terrain Fès', 60, 'Réveil musculaire', 3, 'TERMINE'),
(1, '2024-09-09 17:00:00', 'Complexe Sportif de Fès', 90, 'Analyse vidéo et retour terrain', 1, 'TERMINE');

-- 6. COTISATIONS (200)
INSERT INTO cotisations (user_id, montant, date_paiement, saison, mode_paiement, statut, reference) VALUES
(3, 500.0, '2024-09-01 10:00:00', '2024-2025', 'ESPECES', 'VALIDEE', 'COT-2024-001'),
(3, 500.0, '2024-10-01 09:30:00', '2024-2025', 'CARTE_BANCAIRE', 'VALIDEE', 'COT-2024-056'),
(3, 500.0, '2024-11-01 11:00:00', '2024-2025', 'VIREMENT', 'EN_ATTENTE', 'COT-2024-112');

INSERT INTO cotisations (user_id, montant, date_paiement, saison, mode_paiement, statut, reference, notes) VALUES
(1, 100000.0, '2024-08-15 14:00:00', '2024-2025', 'VIREMENT', 'VALIDEE', 'SPON-PUMA', 'Versement Sponsoring Equipementier Puma Partiel'),
(1, 250000.0, '2024-09-10 10:00:00', '2024-2025', 'VIREMENT', 'VALIDEE', 'SPON-OCP', 'Partenariat OCP Trimestre 1');

-- 7. NOTES TECHNIQUES & ALERTES
INSERT INTO player_technical_notes (player_id, encadrant_id, technical_rating, tactical_rating, physical_rating, strengths, weaknesses, observation, created_at) VALUES
(1, 1, 8, 7, 9, 'Vitesse explosive, jeu de tête', 'Finition parfois imprécise', 'Très bonne forme actuelle', '2024-09-20 18:00:00'),
(4, 1, 9, 8, 7, 'Réflexes sur sa ligne, relance courte', 'Sorties aériennes', 'Leader de la défense', '2024-09-21 10:00:00');

INSERT INTO injury_suspensions (player_id, type, severity, description, start_date, estimated_end_date, status, restrictions) VALUES
(2, 'INJURY', 'MEDIUM', 'Déchirure ischio-jambiers gauche', '2024-11-15', '2025-01-05', 'ACTIVE', 'Repos total, soins quotidiens'),
(5, 'SUSPENSION', 'LOW', 'Cumul de cartons jaunes', '2024-11-20', '2024-11-25', 'ACTIVE', 'Interdiction de match uniquement');
