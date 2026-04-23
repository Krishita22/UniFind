<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
    function api_body(): array { $raw = file_get_contents('php://input'); if ($raw === false || $raw === '') return []; $decoded = json_decode($raw, true); return is_array($decoded) ? $decoded : []; }
}

$body    = api_body();
$offerId = trim($body['offer_id'] ?? '');
$userId  = isset($body['user_id']) ? (int)$body['user_id'] : 0;
$reason  = trim($body['reason']   ?? '');

if ($offerId === '' || $userId <= 0) {
    api_error('Missing required fields: offer_id, user_id.');
}
if ($reason === '') {
    api_error('Please provide a reason for the refund request.');
}

$stmt = $conn->prepare('UPDATE payment_offers SET status = \'refunded\', updated_at = NOW() WHERE offer_id = ? AND buyer_id = ?');
if (!$stmt) { api_error('Server error.', 500); }
$stmt->bind_param('si', $offerId, $userId);
if (!$stmt->execute()) { $stmt->close(); api_error('Failed to submit refund request.', 500); }
$stmt->close();

api_success([
    'offer_id'     => $offerId,
    'status'       => 'refunded',
    'reason'       => $reason,
    'requested_at' => date('Y-m-d H:i:s'),
    'note'         => 'Your refund request has been submitted for review.',
]);
