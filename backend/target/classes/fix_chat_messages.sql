-- ============================================
-- Fix Chat Messages Table Foreign Key Constraint
-- ============================================
-- This script fixes the issue where sending messages to admin fails
-- because equipe_id cannot be NULL

-- Step 1: Drop the problematic foreign key constraint if it exists
-- First, check the constraint name and drop it
ALTER TABLE chat_messages 
DROP FOREIGN KEY IF EXISTS chat_messages_ibfk_1;

-- Step 2: Drop the problematic foreign key if using a different naming pattern
ALTER TABLE chat_messages 
DROP FOREIGN KEY IF EXISTS FKitckk2wbckl0put8r4x4gmqxy;

-- Step 3: Ensure equipe_id column exists and is nullable
ALTER TABLE chat_messages 
MODIFY COLUMN equipe_id BIGINT NULL;

-- Step 4: Add back the foreign key constraint with proper ON DELETE SET NULL
ALTER TABLE chat_messages 
ADD CONSTRAINT FK_chat_messages_equipe 
FOREIGN KEY (equipe_id) REFERENCES equipes(id) ON DELETE SET NULL;

-- Step 5: Verify the table structure
SHOW CREATE TABLE chat_messages;
