-- ============================================
-- Create Message Notifications Table
-- ============================================

CREATE TABLE IF NOT EXISTS message_notifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    body TEXT NOT NULL,
    created_at DATETIME(6) NOT NULL,
    message_id BIGINT,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    sender_id BIGINT,
    sender_name VARCHAR(255),
    team_id BIGINT,
    title VARCHAR(255) NOT NULL,
    type ENUM('TEAM','PRIVATE','BROADCAST','GROUP') NOT NULL,
    user_id BIGINT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Verify the table
SHOW CREATE TABLE message_notifications;
