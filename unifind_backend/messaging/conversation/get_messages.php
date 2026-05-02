<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../crypto.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$convId = (int)($_GET['conversation_id'] ?? 0);
$userId = (int)($_GET['user_id'] ?? 0);
if ($convId <= 0 || $userId <= 0) api_error('conversation_id and user_id required.', 400);

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
while ($row = $res->fetch_assoc()) {
    $row['body'] = decrypt_message_body($row['body'] ?? null);
    $rows[] = $row;
}
$stmt->close();
api_success($rows);
