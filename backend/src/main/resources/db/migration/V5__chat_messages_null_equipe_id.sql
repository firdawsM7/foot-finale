-- Corriger les anciens messages admin (equipe_id=0 invalide pour la FK)
UPDATE chat_messages SET equipe_id = NULL WHERE equipe_id = 0;
