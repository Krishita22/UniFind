<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit();
require_once __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit();
}

$body        = json_decode(file_get_contents('php://input'), true) ?: [];
$userId      = intval($body['user_id']   ?? 0);
$email       = trim($body['email']       ?? '');
$category    = trim($body['category']    ?? '');
$description = trim($body['description'] ?? '');
$steps       = trim($body['steps']       ?? '');

if ($userId === 0 || $email === '' || $category === '' || $description === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields']);
    exit();
}

// Verify user exists
$chk = $conn->prepare("SELECT id FROM users WHERE id = ? LIMIT 1");
$chk->bind_param('i', $userId);
$chk->execute();
$user = $chk->get_result()->fetch_assoc();
$chk->close();

if (!$user) {
    http_response_code(404);
    echo json_encode(['success' => false, 'error' => 'User not found']);
    exit();
}

$stmt = $conn->prepare("
    INSERT INTO bug_reports (user_id, email, category, description, steps)
    VALUES (?, ?, ?, ?, ?)
");
$stmt->bind_param('issss', $userId, $email, $category, $description, $steps);
$ok = $stmt->execute();
$stmt->close();
$conn->close();

echo json_encode(['success' => (bool)$ok]);
?>