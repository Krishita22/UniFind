<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$meetupId = (int)($body['meetup_id'] ?? 0);
$status = (string)($body['status'] ?? '');

if ($meetupId <= 0) api_error('meetup_id required.', 400);
if (empty($status)) api_error('status required.', 400);

// Check if it's a marketplace meetup
$mStmt = $conn->prepare('SELECT id FROM meetups WHERE meetup_id = ? LIMIT 1');
if (!$mStmt) api_error('Prepare error: ' . $conn->error, 500);
$mStmt->bind_param('i', $meetupId);
if (!$mStmt->execute()) api_error('Execute error: ' . $mStmt->error, 500);
$marketplaceMeetup = $mStmt->get_result()->fetch_assoc();
$mStmt->close();

if ($marketplaceMeetup) {
    // Update marketplace meetup
    $stmt = $conn->prepare('UPDATE meetups SET status = ? WHERE meetup_id = ? LIMIT 1');
    if (!$stmt) api_error('Prepare error: ' . $conn->error, 500);
    $stmt->bind_param('si', $status, $meetupId);
    if (!$stmt->execute()) api_error('Execute error: ' . $stmt->error, 500);
    $stmt->close();
    api_success(['updated' => true, 'type' => 'marketplace']);
}

// Check if it's a lost & found meetup
$lfStmt = $conn->prepare('SELECT id FROM lost_found_meetups WHERE id = ? LIMIT 1');
if (!$lfStmt) api_error('Prepare error: ' . $conn->error, 500);
$lfStmt->bind_param('i', $meetupId);
if (!$lfStmt->execute()) api_error('Execute error: ' . $lfStmt->error, 500);
$lfMeetup = $lfStmt->get_result()->fetch_assoc();
$lfStmt->close();

if ($lfMeetup) {
    // Map marketplace statuses to lost & found enum values
    $statusMap = [
        'user_pending' => 'pending',
        'admin_pending' => 'pending',
        'user_cancelled' => 'denied',
        'confirmed' => 'approved',
        'completed' => 'resolved',
    ];
    $mappedStatus = isset($statusMap[$status]) ? $statusMap[$status] : $status;

    // Update lost & found meetup
    $stmt = $conn->prepare('UPDATE lost_found_meetups SET status = ? WHERE id = ? LIMIT 1');
    if (!$stmt) api_error('Prepare error: ' . $conn->error, 500);
    $stmt->bind_param('si', $mappedStatus, $meetupId);
    if (!$stmt->execute()) api_error('Execute error: ' . $stmt->error, 500);
    $stmt->close();
    api_success(['updated' => true, 'type' => 'lost_found']);
}

api_error('Meetup not found.', 404);
?>
