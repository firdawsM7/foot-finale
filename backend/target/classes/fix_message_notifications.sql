-- ============================================
-- Fix Message Notifications Table - Reserved Keyword
-- ============================================
-- 'read' is a reserved keyword in MariaDB
-- This script renames the column to 'is_read'

-- Step 1: Check the current table structure
-- SHOW CREATE TABLE message_notifications;

-- Step 2: Rename the 'read' column to 'is_read'
ALTER TABLE message_notifications 
CHANGE COLUMN `read` `is_read` TINYINT(1) NOT NULL DEFAULT 0;

-- Step 3: Verify the change
SHOW CREATE TABLE message_notifications;
