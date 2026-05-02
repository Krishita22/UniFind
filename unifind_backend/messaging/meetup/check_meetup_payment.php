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

$meetupId = (int)($_GET['meetup_id'] ?? 0);
$userId   = (int)($_GET['user_id']   ?? 0);
if (!$meetupId || !$userId) api_error('meetup_id and user_id required.');

// Get meetup to find item_id, buyer_id, seller_id
$stmt = $conn->prepare("SELECT item_id, buyer_id, seller_id FROM meetups WHERE meetup_id = ? LIMIT 1");
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('i', $meetupId);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
if (!$row) api_error('Meetup not found.', 404);

$isBuyer      = (int)$row['buyer_id'] === $userId;
$isMarketplace = !empty($row['item_id']);

// Seller never needs to pay — always can submit photo
if (!$isBuyer || !$isMarketplace) {
    api_success(['has_paid' => true, 'is_buyer' => $isBuyer, 'is_marketplace' => $isMarketplace]);
}

// Check if buyer has a pending or completed payment offer for this listing
$chk = $conn->prepare("
    SELECT id FROM payment_offers
    WHERE listing_id = ? AND buyer_id = ? AND status IN ('pending', 'completed')
    LIMIT 1
");
if (!$chk) api_error('Server error.', 500);
$chk->bind_param('ii', $row['item_id'], $userId);
$chk->execute();
$offer = $chk->get_result()->fetch_assoc();
$chk->close();

api_success([
    'has_paid'       => !empty($offer),
    'is_buyer'       => $isBuyer,
    'is_marketplace' => $isMarketplace,
    'item_id'        => $row['item_id'],
    'listing_id'     => $row['item_id'],
]);