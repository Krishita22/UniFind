<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); echo json_encode(['success' => false, 'error' => 'Method not allowed.']); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
    function api_body(): array { $raw = file_get_contents('php://input'); if ($raw === false || $raw === '') return []; $decoded = json_decode($raw, true); return is_array($decoded) ? $decoded : []; }
}

$body      = api_body();
$listingId = isset($body['listing_id'])  ? (int)$body['listing_id']    : 0;
$buyerId   = isset($body['buyer_id'])    ? (int)$body['buyer_id']      : 0;
$sellerId  = isset($body['seller_id'])   ? (int)$body['seller_id']     : 0;
$amount    = isset($body['amount'])      ? (float)$body['amount']      : 0.0;
$buyerName = trim($body['buyer_name']       ?? '');
$buyerEmail = trim($body['buyer_email']    ?? '');
$billingAddress = trim($body['billing_address'] ?? '');
$itemTitle  = trim($body['item_title']     ?? '');

if ($listingId <= 0 || $buyerId <= 0 || $sellerId <= 0 || $amount <= 0) {
    api_error('Missing required fields: listing_id, buyer_id, seller_id, amount.');
}
if ($buyerId === $sellerId) {
    api_error('You cannot make an offer on your own listing.');
}

$offerId = 'OFR-' . strtoupper(bin2hex(random_bytes(6)));

// Add item_title column if missing (compatible with older MySQL)
$chk = $conn->query("SHOW COLUMNS FROM payment_offers LIKE 'item_title'");
if ($chk && $chk->num_rows === 0) {
    $conn->query("ALTER TABLE payment_offers ADD COLUMN item_title VARCHAR(255) NOT NULL DEFAULT '' AFTER billing_address");
}

$stmt = $conn->prepare(
    'INSERT INTO payment_offers (offer_id, listing_id, buyer_id, seller_id, amount, buyer_name, buyer_email, billing_address, item_title, status, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, \'pending\', NOW())'
);
if (!$stmt) {
    error_log('create_offer prepare error: ' . $conn->error);
    api_error('Server error creating offer: ' . $conn->error, 500);
}

$stmt->bind_param('siiidssss', $offerId, $listingId, $buyerId, $sellerId, $amount, $buyerName, $buyerEmail, $billingAddress, $itemTitle);
if (!$stmt->execute()) {
    error_log('create_offer execute error: ' . $stmt->error);
    $stmt->close();
    api_error('Failed to create offer: ' . $stmt->error, 500);
}
$stmt->close();

api_success([
    'offer_id'   => $offerId,
    'listing_id' => $listingId,
    'buyer_id'   => $buyerId,
    'seller_id'  => $sellerId,
    'amount'     => $amount,
    'status'     => 'pending',
    'created_at' => date('Y-m-d H:i:s'),
]);
