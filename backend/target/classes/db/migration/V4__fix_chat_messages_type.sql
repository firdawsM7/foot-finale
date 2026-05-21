UPDATE chat_messages SET type = 'TEXT' WHERE type IS NULL OR type = '' OR type = 'CHAT';
UPDATE chat_messages SET type = 'SYSTEM' WHERE type IN ('JOIN', 'LEAVE');
UPDATE chat_messages SET equipe_id = NULL WHERE equipe_id = 0;
