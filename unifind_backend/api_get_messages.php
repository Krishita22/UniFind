<?php
// upload as: get_messages.php
declare(strict_types=1);
require_once __DIR__ . '/api_helpers.php';

$convId = (int)($_GET['conversation_id'] ?? 0);
$userId = (int)($_GET['user_id'] ?? 0);
if ($convId <= 0 || $userId <= 0) api_error('conversation_id and user_id required.', 400);

// Mark messages as read
$upd = $conn->prepare('UPDATE messages SET is_read = 1 WHERE conversation_id = ? AND sender_id != ? AND is_read = 0');
if ($upd) { $upd->bind_param('ii', $convId, $userId); $upd->execute(); $upd->close(); }

$stmt = $conn->prepare(
    'SELECT m.id, m.sender_id, u.username AS sender_name, m.body, m.is_read, m.sent_at
     FROM messages m JOIN users u ON u.id = m.sender_id
     WHERE m.conversation_id = ? ORDER BY m.sent_at ASC'
);
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('i', $convId);
$stmt->execute();
$rows = [];
$res  = $stmt->get_result();
while ($row = $res->fetch_assoc()) $rows[] = $row;
$stmt->close();
api_success($rows);
