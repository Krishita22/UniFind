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
    function api_body(): array {
        $raw = file_get_contents('php://input');
        if ($raw === false || $raw === '') return [];
        $decoded = json_decode($raw, true);
        return is_array($decoded) ? $decoded : [];
    }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body = api_body();
$matchId = (int)($body['match_id'] ?? 0);
$date = (string)($body['meetup_date'] ?? '');
$time = (string)($body['meetup_time'] ?? '');
$location = (string)($body['meetup_location'] ?? '');

if ($matchId <= 0) api_error('match_id required.', 400);
if (empty($date) || empty($time) || empty($location)) api_error('date, time, and location required.', 400);

// Check if match exists
$mStmt = $conn->prepare('SELECT id FROM lost_found_matches WHERE id = ? LIMIT 1');
if (!$mStmt) api_error('Server error.', 500);
$mStmt->bind_param('i', $matchId);
$mStmt->execute();
if (!$mStmt->get_result()->fetch_assoc()) {
    $mStmt->close();
    api_error('Match not found.', 404);
}
$mStmt->close();

// Create meetup
$ins = $conn->prepare('INSERT INTO lost_found_meetups (match_id, meetup_date, meetup_time, meetup_location, status) VALUES (?, ?, ?, ?, "pending")');
if (!$ins) api_error('Failed to prepare: ' . $conn->error, 500);
$ins->bind_param('iss', $matchId, $date, $time, $location);
if (!$ins->execute()) api_error('Failed to create meetup: ' . $ins->error, 500);
$meetupId = $conn->insert_id;
$ins->close();

api_success(['meetup_id' => $meetupId]);
