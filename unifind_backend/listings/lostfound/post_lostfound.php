<?php

// post_lostfound.php
// Accepts a POST request from Flutter and inserts a new lost or found item
// into the lost_found_items table in the database

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config.php';

// Only allowing POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed. Use POST.']);
    exit();
}

// Getting the JSON body sent from Flutter and extracting each field
$data        = json_decode(file_get_contents('php://input'), true);
$title       = isset($data['title'])       ? trim($data['title'])       : '';
$description = isset($data['description']) ? trim($data['description']) : '';
$category    = isset($data['category'])    ? trim($data['category'])    : '';
$type        = isset($data['type'])        ? trim($data['type'])        : '';
$image_url   = isset($data['image'])       ? trim($data['image'])       : '';
$location    = isset($data['location'])    ? trim($data['location'])    : '';
$email       = isset($data['email'])       ? trim($data['email'])       : '';

// Making sure all required fields were provided
if (empty($title) || empty($description) || empty($category) || empty($type) || empty($location) || empty($email)) {
    http_response_code(400);
    echo json_encode([
        'error'    => 'All fields are required.',
        'received' => [
            'title'       => $title,
            'description' => $description,
            'category'    => $category,
            'type'        => $type,
            'location'    => $location,
            'email'       => $email,
        ]
    ]);
    exit();
}

// Looking up the user by their email to get their database ID
$stmt = $conn->prepare('SELECT id FROM users WHERE email = ?');
if (!$stmt) {
    http_response_code(500);
    echo json_encode(['error' => 'Prepare failed (user lookup): ' . $conn->error]);
    exit();
}
$stmt->bind_param('s', $email);
$stmt->execute();
$result = $stmt->get_result();
$user   = $result->fetch_assoc();
$stmt->close();

// If no user was found with that email, return an error message
if (!$user) {
    http_response_code(404);
    echo json_encode(['error' => 'User not found.', 'searched_email' => $email]);
    exit();
}

$poster_id = (int)$user['id'];

// Insert the new lost/found item — status hardcoded as pending
$stmt = $conn->prepare(
    "INSERT INTO lost_found_items (title, description, category, type, image_url, location, poster_id, status)
     VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')"
);

if (!$stmt) {
    http_response_code(500);
    echo json_encode(['error' => 'Prepare failed (insert): ' . $conn->error]);
    exit();
}

$stmt->bind_param('ssssssi', $title, $description, $category, $type, $image_url, $location, $poster_id);

if (!$stmt->execute()) {
    http_response_code(500);
    echo json_encode(['error' => 'Insert failed: ' . $stmt->error]);
    exit();
}

// Getting the auto-generated ID of the new inserted row
$new_id = $stmt->insert_id;
$stmt->close();
$conn->close();

// Return success with the new item's ID
echo json_encode(['success' => true, 'id' => $new_id, 'status' => 'pending']);
?>