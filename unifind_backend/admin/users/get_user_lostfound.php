<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit();
require_once __DIR__ . '/../../config.php';

$userId = (int)($_GET['user_id'] ?? 0);
if ($userId <= 0) { http_response_code(400); echo json_encode(['success' => false, 'error' => 'Missing user_id']); exit(); }

$stmt = $conn->prepare("
    SELECT id, title, description, category, type, image_url, location, status, created_at
    FROM lost_found_items WHERE poster_id = ? ORDER BY created_at DESC
");
$stmt->bind_param('i', $userId);
$stmt->execute();
$res = $stmt->get_result();
$items = [];
while ($row = $res->fetch_assoc()) $items[] = $row;
$stmt->close();
$conn->close();
echo json_encode(['success' => true, 'data' => $items]);
?>