# SevaLink Chat — Testing Guide

## Prerequisites

- Spring Boot backend running on `localhost:8080`
- PostgreSQL running with `sevalink` database
- Two test user accounts (one CLIENT, one WORKER)
- Postman v10+ (import `docs/chat_postman_collection.json`)

---

## 1. Database Setup

### Apply Migration (if tables don't exist)

Run the migration script against your local PostgreSQL database:

```bash
psql -U postgres -d sevalink -f db/migrations/V1__create_chat_tables.sql
```

### Seed Test Users (if not already seeded)

```sql
-- Insert a test client and worker (only if they don't exist)
-- Passwords are bcrypt hashes of "password123"
INSERT INTO users (full_name, email, phone_number, password_hash, role, birthday, is_phone_verified, is_email_verified, is_active, created_at, updated_at)
VALUES
  ('Rajesh Kumar', 'client@example.com', '+94771234567',
   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lh2i', 'CLIENT',
   '1990-01-01', true, true, true, NOW(), NOW()),
  ('Sunil Perera', 'worker@example.com', '+94779876543',
   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lh2i', 'WORKER',
   '1988-05-15', true, true, true, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;
```

### Check Existing Tables

```sql
-- Verify tables exist
\dt chat*

-- Count messages
SELECT COUNT(*) FROM chat_messages;

-- View recent chat rooms
SELECT cr.id, u1.full_name AS user1, u2.full_name AS user2, cr.last_message_at
FROM chat_rooms cr
JOIN users u1 ON u1.id = cr.user1_id
JOIN users u2 ON u2.id = cr.user2_id
ORDER BY cr.last_message_at DESC
LIMIT 10;
```

---

## 2. REST API Testing (Postman)

### Step-by-step

1. **Import collection**: Open Postman → Import → select `docs/chat_postman_collection.json`
2. **Login**: Run `1. Auth → Login` with `client@example.com / password123`
   - The test script auto-saves the JWT to `{{TOKEN}}`
3. **Create Room**: Run `2. Chat Rooms → Get or Create Chat Room` (body: `{"recipientId": 2}`)
   - Auto-saves `{{ROOM_ID}}`
4. **Send Message**: Run `3. Messages → Send Message (REST)` — verify 200 OK with the saved message
5. **Get Messages**: Run `3. Messages → Get Messages in Room`
6. **Unread Count**: Login as the worker, run `4. Unread Count → Get Global Unread Count`

---

## 3. WebSocket Testing

### Option A — Postman WebSocket (easiest)

1. Open Postman → New → WebSocket Request
2. Enter URL: `ws://localhost:8080/ws-chat/websocket`
3. Connect
4. Switch to "Messages" tab
5. Send STOMP CONNECT:

```
CONNECT
Accept-Version:1.2
Authorization:Bearer <paste_jwt_token_here>

```
*(Note: there must be a blank line then a null byte `^@` — Postman handles this automatically)*

6. Subscribe to a room:
```
SUBSCRIBE
id:sub-1
destination:/topic/messages/1

```

7. Open a second Postman WebSocket tab for the other user, subscribe to the same room

8. From the first tab, send:
```
SEND
destination:/app/chat.send
content-type:application/json

{"chatRoomId":1,"recipientId":2,"content":"Hello! Real-time message!","messageType":"TEXT"}
```

9. **Expected**: Second tab instantly receives the message JSON without any polling

### Option B — wscat (terminal)

```bash
npm install -g wscat
wscat -c "ws://localhost:8080/ws-chat/websocket"
```

---

## 4. Read Receipts — Testing Flow

| Tick | Meaning | How to verify |
|------|---------|---------------|
| ✓ Single grey | Sent (saved to DB) | Message appears in `GET /messages` |
| ✓✓ Double grey | Delivered | Recipient's app received it (WebSocket) |
| ✓✓ Double blue | Read | Recipient opened the chat room (GET messages auto-marks read) |

**Test scenario:**
1. Client sends a message to Worker
2. Worker does NOT open the chat → `is_read = false` → double grey tick shown
3. Worker opens the chat room → `GET /api/chat/room/{roomId}/messages` auto-marks as read
4. Client refreshes messages → `is_read = true` → blue double tick shown

**SQL to verify read status:**
```sql
SELECT id, content, is_read, timestamp
FROM chat_messages
WHERE chat_room_id = 1
ORDER BY timestamp DESC
LIMIT 5;
```

---

## 5. Flutter Integration Testing

1. Run `flutter pub get` in `sevalink-app/`
2. Launch Spring Boot backend
3. Start Flutter on Android emulator: `flutter run`
4. Login as Client → navigate to Chat
5. Tap on Worker → verify chat room opens
6. Open a second emulator / browser, login as Worker
7. Send a message from Client
8. **Expected**: Worker's screen updates in real time (< 100ms) without refresh

---

## 6. Folder Structure Reference

### Spring Boot Backend
```
src/main/java/com/sevalink/sevalinkbackend/
├── config/
│   ├── CorsConfig.java              ← Updated: WebSocket headers
│   └── WebSocketConfig.java         ← NEW: STOMP broker config
├── controller/
│   └── ChatController.java          ← Existing REST endpoints
├── dto/
│   ├── ChatMessageDto.java          ← NEW: WS broadcast DTO
│   └── ChatRoomResponse.java        ← Existing
├── model/
│   ├── ChatMessage.java             ← Updated: messageType enum
│   └── ChatRoom.java                ← Existing
├── repository/
│   ├── ChatMessageRepository.java   ← Existing
│   └── ChatRoomRepository.java      ← Existing
├── security/
│   └── SecurityConfig.java          ← Updated: /ws-chat/** permitted
├── service/
│   └── ChatService.java             ← Updated: SimpMessagingTemplate broadcast
└── websocket/
    ├── ChatWebSocketController.java ← NEW: @MessageMapping handler
    └── WebSocketAuthChannelInterceptor.java  ← NEW: JWT on STOMP CONNECT
```

### Flutter App
```
lib/
├── data/
│   ├── models/
│   │   └── chat_models.dart         ← Updated: messageType, senderName fields
│   └── repositories/
│       └── chat_repository.dart     ← Existing (unchanged)
├── features/
│   └── chat/
│       └── screens/
│           ├── chat_list_screen.dart  ← Existing (unchanged)
│           └── chat_room_screen.dart  ← Updated: Live badge, blue ticks, WS-first send
├── providers/
│   ├── chat_provider.dart           ← Updated: WS subscription + 15s fallback poll
│   └── websocket_provider.dart      ← NEW: singleton provider + connection state stream
└── services/
    ├── api_service.dart             ← Existing (unchanged)
    └── websocket_service.dart       ← NEW: STOMP client lifecycle manager
```

---

## 7. Troubleshooting

| Problem | Fix |
|---------|-----|
| WebSocket 403 | Ensure `/ws-chat/**` is in SecurityConfig permitAll |
| CORS error on WS handshake | Check CorsConfig allows the emulator origin |
| `NoSuchBeanDefinitionException: SimpMessagingTemplate` | Ensure `@EnableWebSocketMessageBroker` is on WebSocketConfig |
| Flutter `stomp_dart_client` not found | Run `flutter pub get` in `sevalink-app/` |
| Messages not appearing live | Check backend logs for `Broadcast to /topic/messages/` lines |
| Blue ticks not updating | Recipient must open the chat room to mark as read (by design) |
