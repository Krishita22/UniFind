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

// Pending marketplace listings
$stmt = $conn->prepare("
    SELECT m.id, m.title, m.description, m.price, m.category, m.`condition`,
           m.image_url AS image, m.location, m.created_at,
           u.email AS seller_email, u.username AS seller_username,
           'marketplace' AS type,
           0 AS is_lost_found
    FROM marketplace_items m
    JOIN users u ON m.seller_id = u.id
    WHERE m.status = 'pending'
    ORDER BY m.created_at ASC
");
$stmt->execute();
$res = $stmt->get_result();
while ($row = $res->fetch_assoc()) {
    $row['is_lost_found'] = false;
    $items[] = $row;
}
$stmt->close();

// Pending lost & found items
$stmt2 = $conn->prepare("
    SELECT l.id, l.title, l.description, l.category, l.type,
           l.image_url AS image, l.location, l.created_at,
           0.00 AS price, 'N/A' AS `condition`,
           u.email AS seller_email, u.username AS seller_username,
           1 AS is_lost_found
    FROM lost_found_items l
    JOIN users u ON l.poster_id = u.id
    WHERE l.status = 'pending'
    ORDER BY l.created_at ASC
");
$stmt2->execute();
$res2 = $stmt2->get_result();
while ($row = $res2->fetch_assoc()) {
    $row['is_lost_found'] = true;
    $items[] = $row;
}
$stmt2->close();
$conn->close();

echo json_encode(['success' => true, 'data' => $items]);
?>