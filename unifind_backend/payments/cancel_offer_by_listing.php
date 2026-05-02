<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$body      = json_decode(file_get_contents('php://input'), true) ?? [];
$listingId = (int)($body['listing_id'] ?? 0);
$userId    = (int)($body['user_id']    ?? 0);
if (!$listingId || !$userId) api_error('listing_id and user_id required.');

// Cancel any pending payment offer from this buyer for this listing
$stmt = $conn->prepare("
    UPDATE payment_offers
    SET status = 'cancelled'
    WHERE listing_id = ? AND buyer_id = ? AND status = 'pending'
");
if (!$stmt) api_error('Server error: ' . $conn->error, 500);
$stmt->bind_param('ii', $listingId, $userId);
$stmt->execute();
$affected = $stmt->affected_rows;
$stmt->close();

api_success(['cancelled' => $affected]);