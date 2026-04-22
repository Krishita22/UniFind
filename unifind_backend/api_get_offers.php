<?php
// upload as: get_offers.php
//
// List offers for the current user. Returns every offer where the user is
// either sender or recipient, so a single call powers both "outgoing" and
// "incoming" offer views in the UI.
//
// Query params:
//   user_id   (required, int)
//   filter    (optional: 'sent' | 'received'; default = both)
//   status    (optional: one of pending|accepted|rejected|countered|
//              withdrawn|superseded; default = all)
//   listing_id (optional, int; narrow to a single listing)
//
// Response (JSON):
//   {
//     "success": true,
//     "data": [
//       {
//         "id": int,
//         "listing_id": int,
//         "sender_id": int,
//         "sender_name": string|null,
//         "recipient_id": int,
//         "recipient_name": string|null,
//         "amount": float,
//         "status": string,
//         "parent_offer_id": int|null,
//         "note": string|null,                  // decrypted
//         "created_at": datetime string,
//         "responded_at": datetime string|null,
//         "role": "sender"|"recipient",        // role of the caller on this row
//         "can_respond": bool                   // true iff status=pending and caller=recipient
//       },
//       ...
//     ]
//   }

declare(strict_types=1);
require_once __DIR__ . '/api_helpers.php';
require_once __DIR__ . '/includes/crypto.php';

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

// -----------------------------------------------------------------------
// Build the WHERE clause dynamically while keeping everything parameterized.
// -----------------------------------------------------------------------
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
    default: // both
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
