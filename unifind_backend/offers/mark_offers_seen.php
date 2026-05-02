<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
    function api_body(): array { $raw = file_get_contents('php://input'); if ($raw === false || $raw === '') return []; $decoded = json_decode($raw, true); return is_array($decoded) ? $decoded : []; }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body   = api_body();
$userId = (int)($body['user_id'] ?? 0);
if ($userId <= 0) api_error('user_id required.', 400);

$check = $conn->query(
    "SELECT COUNT(*) AS n FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME   = 'offers'
       AND COLUMN_NAME  = 'seen_at'"
);
$hasSeen = $check && (int)($check->fetch_assoc()['n'] ?? 0) === 1;
if (!$hasSeen) {
    api_success(['cleared' => 0]);
}

$sql =
    "UPDATE offers SET seen_at = NOW()
     WHERE (
           (recipient_id = ? AND status = 'pending' AND seen_at IS NULL)
        OR (sender_id    = ? AND status <> 'pending' AND responded_at IS NOT NULL
            AND (seen_at IS NULL OR seen_at < responded_at))
     )";

$stmt = $conn->prepare($sql);
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('ii', $userId, $userId);
if (!$stmt->execute()) {
    error_log('mark_offers_seen: ' . $stmt->error);
    api_error('Failed to mark offers seen.', 500);
}
$cleared = $stmt->affected_rows;
$stmt->close();

api_success(['cleared' => (int)$cleared]);