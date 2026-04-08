<?php
/**
 * api_get_inbox.php  →  upload as: get_inbox.php
 * Returns all conversations for a user, most recently active first.
 *
 * GET get_inbox.php?user_id=123
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
    'SELECT
         c.id,
         c.subject,
         c.listing_id,
         c.user1_id,
         c.user2_id,
         u1.display_name  AS user1_name,
         u2.display_name  AS user2_name,
         (SELECT m.body
          FROM messages m
          WHERE m.conversation_id = c.id
          ORDER BY m.sent_at DESC
          LIMIT 1)                          AS last_msg,
         (SELECT m.sent_at
          FROM messages m
          WHERE m.conversation_id = c.id
          ORDER BY m.sent_at DESC
          LIMIT 1)                          AS last_at,
         (SELECT COUNT(*)
          FROM messages m
          WHERE m.conversation_id = c.id
            AND m.is_read   = 0
            AND m.sender_id != ?)           AS unread
     FROM conversations c
     JOIN users u1 ON u1.id = c.user1_id
     JOIN users u2 ON u2.id = c.user2_id
     WHERE c.user1_id = ? OR c.user2_id = ?
     ORDER BY last_at DESC'
);

if (!$stmt) {
    api_error('Server error preparing query.', 500);
}

$stmt->bind_param('iii', $userId, $userId, $userId);
$stmt->execute();
$result = $stmt->get_result();

$conversations = [];
while ($row = $result->fetch_assoc()) {
    $conversations[] = [
        'id'         => (int)$row['id'],
        'subject'    => (string)$row['subject'],
        'listing_id' => $row['listing_id'] !== null ? (int)$row['listing_id'] : null,
        'user1_id'   => (int)$row['user1_id'],
        'user2_id'   => (int)$row['user2_id'],
        'user1_name' => (string)$row['user1_name'],
        'user2_name' => (string)$row['user2_name'],
        'last_msg'   => $row['last_msg'] !== null ? (string)$row['last_msg'] : null,
        'last_at'    => $row['last_at']  !== null ? (string)$row['last_at']  : null,
        'unread'     => (int)$row['unread'],
    ];
}
$stmt->close();

api_success(['data' => $conversations]);
