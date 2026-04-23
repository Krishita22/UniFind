<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($userId <= 0) {
    api_error('Missing user_id.');
}

$chk = $conn->query("SHOW COLUMNS FROM payment_offers LIKE 'item_title'");
if ($chk && $chk->num_rows === 0) {
    $conn->query("ALTER TABLE payment_offers ADD COLUMN item_title VARCHAR(255) NOT NULL DEFAULT '' AFTER billing_address");
}

$stmt = $conn->prepare(
    'SELECT offer_id, listing_id, buyer_id, seller_id, amount, buyer_name, buyer_email, billing_address, item_title, status, created_at
     FROM payment_offers WHERE buyer_id = ? OR seller_id = ? ORDER BY created_at DESC'
);
if (!$stmt) { api_error('Server error.', 500); }
$stmt->bind_param('ii', $userId, $userId);
$stmt->execute();
$result = $stmt->get_result();
$offers = [];
while ($row = $result->fetch_assoc()) {
    $offers[] = $row;
}
$stmt->close();

api_success($offers);
