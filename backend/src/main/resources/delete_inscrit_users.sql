-- Exécuter dans phpMyAdmin ou MySQL (base clubdb) pour supprimer tous les comptes INSCRIT
USE clubdb;

DELETE d FROM documents d
INNER JOIN users u ON d.user_id = u.id
WHERE u.role = 'INSCRIT';

DELETE c FROM cotisations c
INNER JOIN users u ON c.user_id = u.id
WHERE u.role = 'INSCRIT';

DELETE n FROM message_notifications n
INNER JOIN users u ON n.user_id = u.id
WHERE u.role = 'INSCRIT';

DELETE m FROM chat_messages m
INNER JOIN users u ON m.sender_id = u.id
WHERE u.role = 'INSCRIT';

DELETE m FROM chat_messages m
INNER JOIN users u ON m.recipient_id = u.id
WHERE u.role = 'INSCRIT';

DELETE p FROM player_technical_notes p
INNER JOIN users u ON p.encadrant_id = u.id
WHERE u.role = 'INSCRIT';

UPDATE equipes e
INNER JOIN users u ON e.encadrant_id = u.id
SET e.encadrant_id = NULL
WHERE u.role = 'INSCRIT';

UPDATE entrainements t
INNER JOIN users u ON t.encadrant_id = u.id
SET t.encadrant_id = NULL
WHERE u.role = 'INSCRIT';

DELETE FROM users WHERE role = 'INSCRIT';
DELETE FROM document_type_config WHERE role = 'INSCRIT';
