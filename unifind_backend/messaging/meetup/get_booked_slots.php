<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$safeSpot = $_GET['safe_spot'] ?? '';
$date     = $_GET['date'] ?? '';

if (empty($safeSpot) || empty($date)) api_error('safe_spot and date required.', 400);

$stmt = $conn->prepare(
    "SELECT meetup_time FROM meetups
     WHERE location = ? AND meetup_date = ? AND status NOT IN ('cancelled', 'denied')"
);

if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('ss', $safeSpot, $date);
$stmt->execute();
$res = $stmt->get_result();
$booked = [];
while ($row = $res->fetch_assoc()) {
    $booked[] = $row['meetup_time'];
}
$stmt->close();
api_success($booked);