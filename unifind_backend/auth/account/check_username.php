<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/../../config.php';

$username = trim($_GET['username'] ?? '');

if ($username === '') {
  echo json_encode(['available' => false]);
  exit;
}

$stmt = $conn->prepare("SELECT id FROM users WHERE username = ? LIMIT 1");
$stmt->bind_param("s", $username);
$stmt->execute();
$stmt->store_result();

echo json_encode(['available' => $stmt->num_rows === 0]);
$stmt->close();