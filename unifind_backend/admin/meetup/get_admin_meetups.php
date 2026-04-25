<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) {
        header('Content-Type: application/json');
        echo json_encode(['success' => true, 'data' => $data]);
        exit;
    }
    function api_error(string $message, int $status = 400) {
        http_response_code($status);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'error' => $message]);
        exit;
    }
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') api_error('Method not allowed.', 405);

$status = isset($_GET['status']) ? (string)$_GET['status'] : 'pending';

$sql = "SELECT m.id, m.match_id, m.meetup_date, m.meetup_time, m.meetup_location, m.status,
               li.title AS lost_title, fi.title AS found_title,
               u_lost.email AS lost_user_email, u_found.email AS found_user_email
        FROM lost_found_meetups m
        JOIN lost_found_matches lm ON m.match_id = lm.id
        LEFT JOIN lost_found_items li ON lm.lost_item_id = li.id
        LEFT JOIN lost_found_items fi ON lm.matched_found_item_id = fi.id
        LEFT JOIN users u_lost ON li.poster_id = u_lost.id
        LEFT JOIN users u_found ON fi.poster_id = u_found.id
        WHERE m.status = ?
        ORDER BY m.meetup_date DESC";

$stmt = $conn->prepare($sql);
if (!$stmt) api_error('Failed to prepare: ' . $conn->error, 500);
$stmt->bind_param('s', $status);
if (!$stmt->execute()) api_error('Failed to query: ' . $stmt->error, 500);

$result = $stmt->get_result();
$meetups = [];
while ($row = $result->fetch_assoc()) {
    $meetups[] = $row;
}
$stmt->close();

api_success($meetups);
