-- =============================================================================
-- SevaLink Chat Feature — PostgreSQL Migration Scripts
-- Version  : V1
-- Tables   : chat_rooms, chat_messages
-- Branch   : chat
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. CHAT ROOMS
--    Stores a conversation channel between any two users (client ↔ worker).
--    The unique constraint on (user1_id, user2_id) ensures one room per pair.
--    user1_id is always the smaller ID to avoid duplicates.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_rooms (
    id                BIGSERIAL       PRIMARY KEY,
    user1_id          BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id          BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at        TIMESTAMP       NOT NULL DEFAULT NOW(),
    last_message_at   TIMESTAMP       NOT NULL DEFAULT NOW(),

    -- Enforce lower-ID user is always user1 (application-side ordering)
    CONSTRAINT chk_user_order    CHECK (user1_id < user2_id),
    CONSTRAINT uq_chat_room_pair UNIQUE (user1_id, user2_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_rooms_user1 ON chat_rooms(user1_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_user2 ON chat_rooms(user2_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_last_msg ON chat_rooms(last_message_at DESC);


-- ---------------------------------------------------------------------------
-- 2. CHAT MESSAGES
--    Every message exchanged within a chat room.
--    is_read supports single/double/blue tick read receipts.
--    message_type allows future image support without schema changes.
-- ---------------------------------------------------------------------------
CREATE TYPE chat_message_type AS ENUM ('TEXT', 'IMAGE');

CREATE TABLE IF NOT EXISTS chat_messages (
    id                BIGSERIAL           PRIMARY KEY,
    chat_room_id      BIGINT              NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id         BIGINT              NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id      BIGINT              NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content           VARCHAR(2000)       NOT NULL,
    message_type      chat_message_type   NOT NULL DEFAULT 'TEXT',
    is_read           BOOLEAN             NOT NULL DEFAULT FALSE,
    timestamp         TIMESTAMP           NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_room       ON chat_messages(chat_room_id, timestamp ASC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_recipient  ON chat_messages(recipient_id, is_read);
CREATE INDEX IF NOT EXISTS idx_chat_messages_unread     ON chat_messages(chat_room_id, recipient_id, is_read)
    WHERE is_read = FALSE;


-- ---------------------------------------------------------------------------
-- 3. SAMPLE DATA  (for local development / Postman testing)
--    Assumes users with id=1 (CLIENT) and id=2 (WORKER) already exist.
--    Remove or comment-out this block in production migrations.
-- ---------------------------------------------------------------------------

/*  -- Uncomment to seed test data:

-- Create a test chat room between user 1 and user 2
INSERT INTO chat_rooms (user1_id, user2_id, created_at, last_message_at)
VALUES (1, 2, NOW(), NOW())
ON CONFLICT (user1_id, user2_id) DO NOTHING;

-- Seed a few messages
DO $$
DECLARE v_room_id BIGINT;
BEGIN
    SELECT id INTO v_room_id FROM chat_rooms WHERE user1_id = 1 AND user2_id = 2;

    INSERT INTO chat_messages (chat_room_id, sender_id, recipient_id, content, message_type, is_read, timestamp)
    VALUES
        (v_room_id, 2, 1, 'Hello! I saw your job posting for electrical wiring. I am available to discuss the details.', 'TEXT', TRUE,  NOW() - INTERVAL '30 minutes'),
        (v_room_id, 1, 2, 'Hi Sunil! Thanks for reaching out. Can you tell me more about your experience with kitchen wiring?', 'TEXT', TRUE,  NOW() - INTERVAL '28 minutes'),
        (v_room_id, 2, 1, 'I have 8 years of experience and have completed over 50 kitchen electrical projects. I can provide references if needed.', 'TEXT', FALSE, NOW() - INTERVAL '25 minutes');
END $$;

*/


-- ---------------------------------------------------------------------------
-- 4. COLUMN ADD (run ONLY if upgrading an existing schema that lacks message_type)
-- ---------------------------------------------------------------------------

/*  -- Uncomment if the table already exists without message_type:

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='chat_messages' AND column_name='message_type'
    ) THEN
        ALTER TABLE chat_messages
            ADD COLUMN message_type chat_message_type NOT NULL DEFAULT 'TEXT';
    END IF;
END $$;

*/
