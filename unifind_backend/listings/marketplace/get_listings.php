<?php

// get_listings.php
// Returns all approved marketplace listings

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed. Use GET.']);
    exit();
}

$category = isset($_GET['category']) ? trim($_GET['category']) : '';

if (!empty($category)) {
    $stmt = $conn->prepare(
        'SELECT m.id, m.title, m.description, m.price, m.category, m.`condition`,
                m.image_url, m.location, m.created_at,
                m.seller_id,
                u.email AS seller_email,
                u.username AS seller
         FROM marketplace_items m
         JOIN users u ON m.seller_id = u.id
         WHERE m.is_active = 1 AND m.status = \'active\' AND m.category = ?
         ORDER BY m.created_at DESC'
    );
    $stmt->bind_param('s', $category);
} else {
    $stmt = $conn->prepare(
        'SELECT m.id, m.title, m.description, m.price, m.category, m.`condition`,
                m.image_url, m.location, m.created_at,
                m.seller_id,
                u.email AS seller_email,
                u.username AS seller
         FROM marketplace_items m
         JOIN users u ON m.seller_id = u.id
         WHERE m.is_active = 1 AND m.status = \'active\'
         ORDER BY m.created_at DESC'
    );
}

$stmt->execute();
$result = $stmt->get_result();

$listings = [];
while ($row = $result->fetch_assoc()) {
    $listings[] = [
        'id'              => $row['id'],
        'title'           => $row['title'],
        'description'     => $row['description'],
        'price'           => (float) $row['price'],
        'category'        => $row['category'],
        'condition'       => $row['condition'],
        'image'           => $row['image_url'],
        'location'        => $row['location'],
        'seller'          => $row['seller'],
        'seller_username' => $row['seller'],
        'createdAt'       => $row['created_at'],
        'seller_id'       => (int)$row['seller_id'],
        'seller_email'    => $row['seller_email']
    ];
}

$stmt->close();
$conn->close();

echo json_encode(['success' => true, 'data' => $listings]);
?>
