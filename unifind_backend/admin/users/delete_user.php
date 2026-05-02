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
$email  = trim($body['email'] ?? '');

if ($userId <= 0 || $email === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields']);
    exit();
}

// Get username before deleting
$r = $conn->prepare("SELECT username FROM users WHERE id = ? LIMIT 1");
$r->bind_param('i', $userId);
$r->execute();
$row = $r->get_result()->fetch_assoc();
$r->close();
$username = $row['username'] ?? '';

// Delete all their marketplace listings
$d1 = $conn->prepare("DELETE FROM marketplace_items WHERE seller_id = ?");
$d1->bind_param('i', $userId);
$d1->execute();
$d1->close();

// Delete all their lost & found posts
$d2 = $conn->prepare("DELETE FROM lost_found_items WHERE poster_id = ?");
$d2->bind_param('i', $userId);
$d2->execute();
$d2->close();

// Delete the user
$d3 = $conn->prepare("DELETE FROM users WHERE id = ?");
$d3->bind_param('i', $userId);
$ok = $d3->execute();
$d3->close();

// NOTE: Intentionally NOT adding to email_blacklist so the user can re-register

// Log activity
$desc = "User account deleted: @$username ($email)";
$alog = $conn->prepare("INSERT INTO admin_activity_log (description, type) VALUES (?, 'user')");
$alog->bind_param('s', $desc);
$alog->execute();
$alog->close();

$conn->close();
echo json_encode(['success' => (bool)$ok]);
?>