<?php
/**
 * api_send_message.php  →  upload as: send_message.php
 * Inserts a new message into an existing conversation.
 *
 * POST send_message.php
 * Body (JSON): { "conversation_id": 1, "sender_id": 123, "body": "Hello!" }
 */

declare(strict_types=1);

require_once __DIR__ . '/api_helpers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error('Method not allowed.', 405);
}

$body     = api_body();
$convId   = (int)($body['conversation_id'] ?? 0);
$senderId = (int)($body['sender_id']       ?? 0);
$text     = trim((string)($body['body']    ?? ''));

if ($convId   <= 0) api_error('conversation_id is required.', 400, 'MISSING_FIELD');
if ($senderId <= 0) api_error('sender_id is required.',       400, 'MISSING_FIELD');
if ($text    === '') api_error('Message body cannot be empty.', 400, 'MISSING_FIELD');
if (mb_strlen($text) > 3000) api_error('Message is too long (max 3000 characters).', 400, 'TOO_LONG');

// Verify the sender belongs to this conversation
$check = $conn->prepare(
    'SELECT id FROM conversations
     WHERE id = ? AND (user1_id = ? OR user2_id = ?) LIMIT 1'
);
if (!$check) api_error('Server error.', 500);

$check->bind_param('iii', $convId, $senderId, $senderId);
$check->execute();
$belongs = $check->get_result()->fetch_assoc();
$check->close();

if (!$belongs) {
    api_error('Conversation not found or access denied.', 404, 'NOT_FOUND');
}

// Insert the message
$stmt = $conn->prepare(
    'INSERT INTO messages (conversation_id, sender_id, body, is_read, sent_at)
     VALUES (?, ?, ?, 0, NOW())'
);
if (!$stmt) api_error('Server error preparing insert.', 500);

$stmt->bind_param('iis', $convId, $senderId, $text);

if (!$stmt->execute()) {
    error_log('send_message insert error: ' . $stmt->error);
    $stmt->close();
    api_error('Could not send message. Please try again.', 500);
}

$newId = (int)$stmt->insert_id;
$stmt->close();

api_success(['message_id' => $newId]);
