<?php
/**
 * api_get_messages.php  →  upload as: get_messages.php
 * Returns all messages in a conversation and marks incoming ones as read.
 *
 * GET get_messages.php?conversation_id=1&user_id=123
 */

declare(strict_types=1);

require_once __DIR__ . '/api_helpers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    api_error('Method not allowed.', 405);
}

$convId = (int)($_GET['conversation_id'] ?? 0);
$userId = (int)($_GET['user_id']         ?? 0);

if ($convId <= 0) api_error('conversation_id is required.', 400, 'MISSING_FIELD');
if ($userId <= 0) api_error('user_id is required.',         400, 'MISSING_FIELD');

// Verify the requesting user belongs to this conversation
$check = $conn->prepare(
    'SELECT id FROM conversations
     WHERE id = ? AND (user1_id = ? OR user2_id = ?) LIMIT 1'
);
if (!$check) api_error('Server error.', 500);

$check->bind_param('iii', $convId, $userId, $userId);
$check->execute();
$belongs = $check->get_result()->fetch_assoc();
$check->close();

if (!$belongs) {
    api_error('Conversation not found or access denied.', 404, 'NOT_FOUND');
}

// Mark all incoming messages as read
$markRead = $conn->prepare(
    'UPDATE messages
     SET is_read = 1
     WHERE conversation_id = ? AND sender_id != ? AND is_read = 0'
);
if ($markRead) {
    $markRead->bind_param('ii', $convId, $userId);
    $markRead->execute();
    $markRead->close();
}

// Fetch all messages oldest-first, joining display_name from users
$stmt = $conn->prepare(
    'SELECT m.id, m.sender_id, u.display_name AS sender_name, m.body, m.sent_at
     FROM messages m
     JOIN users u ON u.id = m.sender_id
     WHERE m.conversation_id = ?
     ORDER BY m.sent_at ASC'
);
if (!$stmt) api_error('Server error preparing query.', 500);

$stmt->bind_param('i', $convId);
$stmt->execute();
$result = $stmt->get_result();

$messages = [];
while ($row = $result->fetch_assoc()) {
    $messages[] = [
        'id'          => (int)$row['id'],
        'sender_id'   => (int)$row['sender_id'],
        'sender_name' => (string)$row['sender_name'],
        'body'        => (string)$row['body'],
        'sent_at'     => (string)$row['sent_at'],
    ];
}
$stmt->close();

api_success(['data' => $messages]);
