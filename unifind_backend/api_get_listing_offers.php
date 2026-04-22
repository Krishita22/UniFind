<?php
// upload as: get_listing_offers.php
//
// List offers on a specific listing from the caller's perspective.
// The caller sees only offers in which they are the sender OR the recipient;
// this means the seller sees every offer (they're the recipient of every
// opener, sender of their own counters) while a buyer sees only their own
// negotiation threads — without us needing a server-side listing-ownership
// check that would require coupling to marketplace_items vs. listings.
//
// Query params:
//   listing_id (required, int)
//   user_id    (required, int)
//
// Response is the same shape as api_get_offers.php.

declare(strict_types=1);
require_once __DIR__ . '/api_helpers.php';
require_once __DIR__ . '/includes/crypto.php';

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
     ORDER BY o.created_at ASC'; // oldest-first so the UI can render each
                                 // thread's opener -> counters in natural order

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
