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

$id          = (int)($body['id'] ?? 0);
$title       = trim($body['title'] ?? '');
$description = trim($body['description'] ?? '');
$price       = (float)($body['price'] ?? 0);
$category    = trim($body['category'] ?? '');
$condition   = trim($body['condition'] ?? '');
$email       = trim($body['email'] ?? '');
$image       = trim($body['image'] ?? $body['image_url'] ?? '');

// ── location removed from required check ──────────────────────────────────────
if ($id <= 0 || $title === '' || $description === '' || $price <= 0 || $category === '' || $condition === '' || $email === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields']);
    exit();
}

$u = $conn->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
$u->bind_param('s', $email);
$u->execute();
$user = $u->get_result()->fetch_assoc();
$u->close();

if (!$user) {
    http_response_code(404);
    echo json_encode(['success' => false, 'error' => 'User not found']);
    exit();
}
$userId = (int)$user['id'];

$own = $conn->prepare('SELECT id FROM marketplace_items WHERE id = ? AND seller_id = ? LIMIT 1');
$own->bind_param('ii', $id, $userId);
$own->execute();
$owned = $own->get_result()->fetch_assoc();
$own->close();

if (!$owned) {
    http_response_code(403);
    echo json_encode(['success' => false, 'error' => 'Not allowed to edit this listing']);
    exit();
}

if ($image !== '') {
    $upd = $conn->prepare(
        'UPDATE marketplace_items
         SET title = ?, description = ?, price = ?, category = ?, `condition` = ?, image_url = ?, status = \'pending\'
         WHERE id = ?'
    );
    $upd->bind_param('ssdssi', $title, $description, $price, $category, $condition, $image, $id);
} else {
    $upd = $conn->prepare(
        'UPDATE marketplace_items
         SET title = ?, description = ?, price = ?, category = ?, `condition` = ?, status = \'pending\'
         WHERE id = ?'
    );
    $upd->bind_param('ssdssi', $title, $description, $price, $category, $condition, $id);
}

$ok = $upd->execute();
$upd->close();
$conn->close();

echo json_encode(['success' => (bool)$ok]);
?>