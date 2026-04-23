<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
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

$stmt = $conn->prepare('SELECT last_active FROM users WHERE id = ? LIMIT 1');
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('i', $userId);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
if (!$row) api_error('User not found.', 404);

$lastActive = $row['last_active'];
$online = false;
if ($lastActive !== null) {
    $diff = time() - strtotime($lastActive);
    $online = $diff < 120; // online if active in last 2 minutes
}
api_success(['user_id' => $userId, 'online' => $online, 'last_active' => $lastActive]);
