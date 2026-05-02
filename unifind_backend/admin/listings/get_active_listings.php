<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit();

require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit();
}

$items = [];

$stmt = $conn->prepare("
    SELECT m.id, m.title, m.description, m.price, m.category, m.`condition`,
           m.image_url AS image, m.location, m.created_at,
           u.email AS seller_email, u.username AS seller_username,
           'marketplace' AS type
    FROM marketplace_items m
    JOIN users u ON m.seller_id = u.id
    WHERE m.status = 'active' AND m.is_active = 1
    ORDER BY m.created_at DESC
");
$stmt->execute();
$res = $stmt->get_result();
while ($row = $res->fetch_assoc()) {
    $row['is_lost_found'] = false;
    $items[] = $row;
}
$stmt->close();
$conn->close();

echo json_encode(['success' => true, 'data' => $items]);
?>