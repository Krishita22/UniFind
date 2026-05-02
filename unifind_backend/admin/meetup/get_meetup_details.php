<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$meetupId = (int)($_GET['meetup_id'] ?? 0);
if (!$meetupId) api_error('meetup_id required.');

// Try marketplace first
$stmt = $conn->prepare("
    SELECT meetup_id, status, buyer_photo_url, seller_photo_url, item_id, buyer_id, seller_id
    FROM meetups WHERE meetup_id = ? LIMIT 1
");
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('i', $meetupId);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if ($row) {
    api_success($row);
}

// Try lost & found
$stmt2 = $conn->prepare("
    SELECT id AS meetup_id, status, buyer_photo_url, seller_photo_url,
           NULL AS item_id, NULL AS buyer_id, NULL AS seller_id
    FROM lost_found_meetups WHERE id = ? LIMIT 1
");
if (!$stmt2) api_error('Server error.', 500);
$stmt2->bind_param('i', $meetupId);
$stmt2->execute();
$row2 = $stmt2->get_result()->fetch_assoc();
$stmt2->close();

if (!$row2) api_error('Meetup not found.', 404);

api_success($row2);
?>