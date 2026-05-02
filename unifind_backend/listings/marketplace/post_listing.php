<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');
require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed. Use POST.']);
    exit();
}

$data        = json_decode(file_get_contents('php://input'), true);
$title       = isset($data['title'])       ? trim($data['title'])       : '';
$description = isset($data['description']) ? trim($data['description']) : '';
$price       = isset($data['price'])       ? (float)$data['price']      : 0;
$category    = isset($data['category'])    ? trim($data['category'])    : '';
$condition   = isset($data['condition'])   ? trim($data['condition'])   : '';
$image_url   = isset($data['image'])       ? trim($data['image'])       : '';
$email       = isset($data['email'])       ? trim($data['email'])       : '';

// ── location removed — marketplace listings don't have a location ─────────────
if (empty($title) || empty($description) || empty($category) || empty($condition) || empty($email)) {
    http_response_code(400);
    echo json_encode(['error' => 'All fields are required.']);
    exit();
}

$stmt = $conn->prepare('SELECT id FROM users WHERE email = ?');
$stmt->bind_param('s', $email);
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$user) {
    http_response_code(404);
    echo json_encode(['error' => 'User not found.']);
    exit();
}

$seller_id = $user['id'];

// ── location removed from INSERT too ─────────────────────────────────────────
$stmt = $conn->prepare(
    'INSERT INTO marketplace_items (title, description, price, category, `condition`, image_url, seller_id, status, is_active)
     VALUES (?, ?, ?, ?, ?, ?, ?, "pending", 0)'
);

$stmt->bind_param('ssdsssi', $title, $description, $price, $category, $condition, $image_url, $seller_id);
$stmt->execute();

$new_id = $stmt->insert_id;
$stmt->close();
$conn->close();

echo json_encode(['success' => true, 'id' => $new_id]);
?>