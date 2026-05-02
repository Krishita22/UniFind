<?php
declare(strict_types=1);
require_once __DIR__ . '/../../../config.php';
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }
if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$userId = (int)($_GET['user_id'] ?? 0);
if ($userId <= 0) api_error('user_id required.', 400);

// Get approved claims where this user is the claimant OR the item poster
$stmt = $conn->prepare(
    "SELECT c.id AS claim_id, c.found_item_id AS item_id, c.claimant_id, c.status,
            lf.poster_id, lf.title AS item_title,
            conv.id AS conversation_id
     FROM lost_found_claims c
     JOIN lost_found_items lf ON lf.id = c.found_item_id
     LEFT JOIN conversations conv ON conv.listing_id = c.found_item_id
         AND ((conv.user1_id = c.claimant_id AND conv.user2_id = lf.poster_id)
           OR (conv.user1_id = lf.poster_id AND conv.user2_id = c.claimant_id))
     WHERE c.status = 'approved' AND (c.claimant_id = ? OR lf.poster_id = ?)"
);
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('ii', $userId, $userId);
$stmt->execute();
$rows = [];
$res = $stmt->get_result();
while ($row = $res->fetch_assoc()) $rows[] = $row;
$stmt->close();
api_success($rows);
