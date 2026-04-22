<?php
// get_offers.php — list offers for the current user (sender or recipient).
//
// Query params:
//   user_id    (required, int)
//   filter     (optional: 'sent' | 'received'; default = both)
//   status     (optional: pending|accepted|rejected|countered|withdrawn|superseded)
//   listing_id (optional, int; narrow to one listing)

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

$userId    = (int)($_GET['user_id'] ?? 0);
$filter    = strtolower(trim((string)($_GET['filter'] ?? '')));
$status    = strtolower(trim((string)($_GET['status'] ?? '')));
$listingId = (int)($_GET['listing_id'] ?? 0);

if ($userId <= 0) api_error('user_id is required.', 400);

$validStatuses = ['pending','accepted','rejected','countered','withdrawn','superseded'];
if ($status !== '' && !in_array($status, $validStatuses, true)) {
    api_error('Invalid status.', 400);
}
if ($filter !== '' && $filter !== 'sent' && $filter !== 'received') {
    api_error("filter must be 'sent' or 'received'.", 400);
}

$where  = [];
$types  = '';
$params = [];

switch ($filter) {
    case 'sent':
        $where[]  = 'o.sender_id = ?';
        $types   .= 'i';
        $params[] = $userId;
        break;
    case 'received':
        $where[]  = 'o.recipient_id = ?';
        $types   .= 'i';
        $params[] = $userId;
        break;
    default:
        $where[]  = '(o.sender_id = ? OR o.recipient_id = ?)';
        $types   .= 'ii';
        $params[] = $userId;
        $params[] = $userId;
        break;
}

if ($status !== '') {
    $where[]  = 'o.status = ?';
    $types   .= 's';
    $params[] = $status;
}
if ($listingId > 0) {
    $where[]  = 'o.listing_id = ?';
    $types   .= 'i';
    $params[] = $listingId;
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
     WHERE ' . implode(' AND ', $where) . '
     ORDER BY o.created_at DESC';

$stmt = $conn->prepare($sql);
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param($types, ...$params);
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
