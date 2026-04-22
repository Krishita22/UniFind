<?php
declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once __DIR__ . '/../api_helpers.php';

$body = api_body();

$offerId = trim($body['offer_id'] ?? '');
$userId  = isset($body['user_id']) ? (int)$body['user_id'] : 0;
$reason  = trim($body['reason']   ?? '');

if ($offerId === '' || $userId <= 0) {
    api_error('Missing required fields: offer_id, user_id.');
}
if ($reason === '') {
    api_error('Please provide a reason for the refund request.');
}

// Simulated — no real refund is processed
$refundId = 'RFD-' . strtoupper(bin2hex(random_bytes(6)));

api_success([
    'refund_id'    => $refundId,
    'offer_id'     => $offerId,
    'user_id'      => $userId,
    'reason'       => $reason,
    'status'       => 'pending',
    'requested_at' => date('Y-m-d H:i:s'),
    'note'         => 'Your refund request has been submitted for review.',
]);
