UPDATE chat_messages SET deleted = 0 WHERE deleted IS NULL;
ALTER TABLE chat_messages MODIFY deleted TINYINT(1) NOT NULL DEFAULT 0;
