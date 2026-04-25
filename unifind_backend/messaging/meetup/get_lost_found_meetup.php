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

if ($_SERVER['REQUEST_METHOD'] !== 'GET') api_error('Method not allowed.', 405);

$matchId = (int)($_GET['match_id'] ?? 0);
$itemId = (int)($_GET['item_id'] ?? 0);

if ($matchId <= 0 && $itemId <= 0) api_error('match_id or item_id required.', 400);

if ($matchId > 0) {
    $stmt = $conn->prepare('SELECT id, match_id, meetup_date, meetup_time, meetup_location, status FROM lost_found_meetups WHERE match_id = ? LIMIT 1');
    if (!$stmt) api_error('Failed to prepare: ' . $conn->error, 500);
    $stmt->bind_param('i', $matchId);
} else {
    $stmt = $conn->prepare('
        SELECT m.id, m.match_id, m.meetup_date, m.meetup_time, m.meetup_location, m.status
        FROM lost_found_meetups m
        JOIN lost_found_matches lm ON m.match_id = lm.id
        WHERE lm.lost_item_id = ? OR lm.matched_found_item_id = ?
        LIMIT 1
    ');
    if (!$stmt) api_error('Failed to prepare: ' . $conn->error, 500);
    $stmt->bind_param('ii', $itemId, $itemId);
}

if (!$stmt->execute()) api_error('Failed to query: ' . $stmt->error, 500);

$result = $stmt->get_result();
$meetup = $result->fetch_assoc();
$stmt->close();

api_success($meetup);
