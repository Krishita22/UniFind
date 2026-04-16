<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
    function api_body(): array { $raw = file_get_contents('php://input'); if ($raw === false || $raw === '') return []; $decoded = json_decode($raw, true); return is_array($decoded) ? $decoded : []; }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body    = api_body();
$lid     = (int)($body['listing_id'] ?? 0);
$u1      = (int)($body['user1_id']   ?? 0);
$u2      = (int)($body['user2_id']   ?? 0);
$subject = trim((string)($body['subject'] ?? 'Conversation'));

if ($u1 <= 0 || $u2 <= 0) api_error('user IDs required.', 400);
if ($u1 === $u2) api_error('Cannot message yourself.', 400);

$lidOrNull = $lid > 0 ? $lid : null;
if ($lidOrNull !== null) {
    $find = $conn->prepare('SELECT id FROM conversations WHERE listing_id=? AND ((user1_id=? AND user2_id=?) OR (user1_id=? AND user2_id=?)) LIMIT 1');
    if ($find) { $find->bind_param('iiiii', $lidOrNull, $u1, $u2, $u2, $u1); $find->execute(); $row = $find->get_result()->fetch_assoc(); $find->close(); if ($row) api_success(['id' => (int)$row['id'], 'is_new' => false]); }
} else {
    $find = $conn->prepare('SELECT id FROM conversations WHERE listing_id IS NULL AND ((user1_id=? AND user2_id=?) OR (user1_id=? AND user2_id=?)) LIMIT 1');
    if ($find) { $find->bind_param('iiii', $u1, $u2, $u2, $u1); $find->execute(); $row = $find->get_result()->fetch_assoc(); $find->close(); if ($row) api_success(['id' => (int)$row['id'], 'is_new' => false]); }
}

$ins = $conn->prepare('INSERT INTO conversations (listing_id, user1_id, user2_id, subject, created_at) VALUES (?, ?, ?, ?, NOW())');
if (!$ins) api_error('Server error.', 500);
$ins->bind_param('iiis', $lidOrNull, $u1, $u2, $subject);
if (!$ins->execute()) api_error('Failed to create conversation.', 500);
$convId = (int)$ins->insert_id;
$ins->close();

$opener = "Hi! I wanted to reach out about your post. Can we arrange a time to meet?";
$mIns = $conn->prepare('INSERT INTO messages (conversation_id, sender_id, body, is_read, sent_at) VALUES (?, ?, ?, 0, NOW())');
if ($mIns) { $mIns->bind_param('iis', $convId, $u1, $opener); $mIns->execute(); $mIns->close(); }

api_success(['id' => $convId, 'is_new' => true]);
