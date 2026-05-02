<?php

// get_lostfound.php
// Returns all active lost & found posts

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../../config.php';

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed. Use GET.']);
    exit();
}

// Optional filters passed as query params
$type     = isset($_GET['type'])     ? trim($_GET['type'])     : '';
$category = isset($_GET['category']) ? trim($_GET['category']) : '';

// Base query 
// Join with users table to get the poster's display name
$sql = 'SELECT l.id, l.title, l.description, l.category, l.type,
               l.image_url, l.location, l.status, l.created_at,
               l.poster_id,
               u.email AS poster_email,
               u.username AS poster


        FROM lost_found_items l
        JOIN users u ON l.poster_id = u.id
        WHERE l.status = "active"';

// Adding optional filters
$params      = [];
$param_types = '';

if (!empty($type)) {
    $sql          .= ' AND l.type = ?';
    $params[]      = $type;
    $param_types  .= 's';
}

if (!empty($category)) {
    $sql          .= ' AND l.category = ?';
    $params[]      = $category;
    $param_types  .= 's';
}

$sql .= ' ORDER BY l.created_at DESC';

$stmt = $conn->prepare($sql);

// Binding params only if filters were applied
if (!empty($params)) {
    $stmt->bind_param($param_types, ...$params);
}

$stmt->execute();
$result = $stmt->get_result();

// Creating the response array
$items = [];
while ($row = $result->fetch_assoc()) {
    $items[] = [
        'id'          => $row['id'],
        'title'       => $row['title'],
        'description' => $row['description'],
        'category'    => $row['category'],
        'type'        => $row['type'],
        'image'       => $row['image_url'],
        'location'    => $row['location'],
        'status'      => $row['status'],
        'poster'      => $row['poster'],
        'poster_username' => $row['poster'],
        'createdAt'   => $row['created_at'],
        'poster_id'    => (int)$row['poster_id'],
        'poster_email' => $row['poster_email']

    ];
}

$stmt->close();
$conn->close();

echo json_encode(['success' => true, 'data' => $items]);
?>




