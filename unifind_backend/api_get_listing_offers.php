<?php
// get_listing_offers.php — offers on a specific listing, scoped to the caller.
//
// Caller sees only offers in which they are sender or recipient, so the
// seller sees every offer on their listing, a buyer sees only their own
// negotiation threads — no server-side listing-ownership check needed.
//
// Query params:
//   listing_id (required, int)
//   user_id    (required, int)

declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../crypto.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$listingId = (int)($_GET['listing_id'] ?? 0);
$userId    = (int)($_GET['user_id']    ?? 0);

if ($listingId <= 0 || $userId <= 0) {
    api_error('listing_id and user_id are required.', 400);
}

$sql =
    'SELECT
         o.id, o.listing_id,
         o.sender_id, us.username AS sender_name,
         o.recipient_id, ur.username AS recipient_name,
         o.amount, o.status, o.parent_offer_id, o.note,
         o.created_at, o.responded_at
     FROM offers o
     LEFT JOIN users us ON us.id = o.sender_id
     LEFT JOIN users ur ON ur.id = o.recipient_id
     WHERE o.listing_id = ?
       AND (o.sender_id = ? OR o.recipient_id = ?)
     ORDER BY o.created_at ASC';

$stmt = $conn->prepare($sql);
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('iii', $listingId, $userId, $userId);
$stmt->execute();
$res = $stmt->get_result();

$rows = [];
while ($row = $res->fetch_assoc()) {
    $row['amount']          = (float)$row['amount'];
    $row['parent_offer_id'] = $row['parent_offer_id'] !== null ? (int)$row['parent_offer_id'] : null;
    $row['note']            = decrypt_message_body($row['note'] ?? null);
    $isRecipient            = ((int)$row['recipient_id'] === $userId);
    $row['role']            = $isRecipient ? 'recipient' : 'sender';
    $row['can_respond']     = ($isRecipient && $row['status'] === 'pending');
    $rows[] = $row;
}
$stmt->close();

api_success($rows);
