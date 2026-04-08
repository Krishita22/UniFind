<?php
/**
 * api_get_unread_count.php  →  upload as: get_unread_count.php
 * Returns total unread message count for a user across all conversations.
 *
 * GET get_unread_count.php?user_id=123
 */

declare(strict_types=1);

require_once __DIR__ . '/api_helpers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    api_error('Method not allowed.', 405);
}

$userId = (int)($_GET['user_id'] ?? 0);
if ($userId <= 0) {
    api_error('user_id is required.', 400, 'MISSING_FIELD');
}

$stmt = $conn->prepare(
    'SELECT COUNT(*) AS cnt
     FROM messages m
     JOIN conversations c ON c.id = m.conversation_id
     WHERE m.is_read   = 0
       AND m.sender_id != ?
       AND (c.user1_id = ? OR c.user2_id = ?)'
);
if (!$stmt) api_error('Server error.', 500);

$stmt->bind_param('iii', $userId, $userId, $userId);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

api_success(['count' => (int)($row['cnt'] ?? 0)]);
