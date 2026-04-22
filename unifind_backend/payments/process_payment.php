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

if ($offerId === '' || $userId <= 0) {
    api_error('Missing required fields: offer_id, user_id.');
}

// Simulated payment confirmation — no real charge is made
$txnId = 'TXN-' . strtoupper(bin2hex(random_bytes(8)));

api_success([
    'transaction_id' => $txnId,
    'offer_id'       => $offerId,
    'user_id'        => $userId,
    'status'         => 'completed',
    'processed_at'   => date('Y-m-d H:i:s'),
    'note'           => 'This is a simulated payment. No real charge was made.',
]);
