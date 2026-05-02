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
}

$userId = (int)($_GET['user_id'] ?? 0);
if ($userId <= 0) api_error('user_id required.', 400);

$stmt = $conn->prepare(
    'SELECT COUNT(*) AS cnt FROM messages m
     JOIN conversations c ON c.id = m.conversation_id
     WHERE m.is_read = 0 AND m.sender_id != ? AND (c.user1_id = ? OR c.user2_id = ?)'
);
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('iii', $userId, $userId, $userId);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
api_success(['count' => (int)($row['count'] ?? $row['cnt'] ?? 0)]);
