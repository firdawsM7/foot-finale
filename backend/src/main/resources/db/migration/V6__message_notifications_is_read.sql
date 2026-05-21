-- Rename reserved column 'read' to 'is_read' when upgrading an older schema.
-- Safe to run: only executes if the legacy column still exists.
SET @has_read_col := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'message_notifications'
      AND COLUMN_NAME = 'read'
);
SET @sql := IF(
    @has_read_col > 0,
    'ALTER TABLE message_notifications CHANGE COLUMN `read` `is_read` TINYINT(1) NOT NULL DEFAULT 0',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
