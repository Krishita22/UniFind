<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit();
require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit();
}

$body = json_decode(file_get_contents('php://input'), true) ?: [];
$userId    = (int)($body['user_id'] ?? 0);
$avatarUrl = trim($body['avatar_url'] ?? '');

if ($userId <= 0 || $avatarUrl === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields']);
    exit();
}

$stmt = $conn->prepare('UPDATE users SET avatar_url = ? WHERE id = ?');
$stmt->bind_param('si', $avatarUrl, $userId);
$ok = $stmt->execute();
$stmt->close();
$conn->close();

echo json_encode(['success' => (bool)$ok]);
?>