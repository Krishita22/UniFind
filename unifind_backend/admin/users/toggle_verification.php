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

$body   = json_decode(file_get_contents('php://input'), true) ?: [];
$userId = (int)($body['user_id'] ?? 0);
$verify = (bool)($body['verify'] ?? true);

if ($userId <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing user_id']);
    exit();
}

$isActive = $verify ? 1 : 0;
$upd = $conn->prepare("UPDATE users SET is_active = ? WHERE id = ?");
$upd->bind_param('ii', $isActive, $userId);
$ok = $upd->execute();
$upd->close();

// Log activity
$r = $conn->prepare("SELECT username FROM users WHERE id = ? LIMIT 1");
$r->bind_param('i', $userId);
$r->execute();
$row = $r->get_result()->fetch_assoc();
$r->close();
$username = $row['username'] ?? '';
$action = $verify ? 'verified' : 'unverified';
$desc = "User email $action: @$username";
$alog = $conn->prepare("INSERT INTO admin_activity_log (description, type) VALUES (?, 'user')");
$alog->bind_param('s', $desc);
$alog->execute();
$alog->close();

$conn->close();
echo json_encode(['success' => (bool)$ok]);
?>