<?php
declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once __DIR__ . '/../api_helpers.php';

$body = api_body();

$listingId = isset($body['listing_id']) ? (int)$body['listing_id'] : 0;
$buyerId   = isset($body['buyer_id'])   ? (int)$body['buyer_id']   : 0;
$sellerId  = isset($body['seller_id'])  ? (int)$body['seller_id']  : 0;
$amount    = isset($body['amount'])     ? (float)$body['amount']   : 0.0;

if ($listingId <= 0 || $buyerId <= 0 || $sellerId <= 0 || $amount <= 0) {
    api_error('Missing required fields: listing_id, buyer_id, seller_id, amount.');
}
if ($buyerId === $sellerId) {
    api_error('You cannot make an offer on your own listing.');
}

// Simulated — generate an offer record without storing payment info
$offerId = 'OFR-' . strtoupper(bin2hex(random_bytes(6)));

api_success([
    'offer_id'   => $offerId,
    'listing_id' => $listingId,
    'buyer_id'   => $buyerId,
    'seller_id'  => $sellerId,
    'amount'     => $amount,
    'status'     => 'pending',
    'created_at' => date('Y-m-d H:i:s'),
]);
