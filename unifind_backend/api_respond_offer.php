<?php
// upload as: respond_offer.php
//
// Resolve a pending offer: accept / reject / withdraw.
// (A "counter" is NOT handled here — it's a new offer with parent_offer_id,
//  created via make_offer.php.)
//
// Action rules:
//   accept   : current user must be the offer's recipient. On success, any
//              OTHER pending offers on the same listing are flipped to
//              'superseded' in the same transaction so they don't sit orphaned
//              waiting for a response that will never come.
//   reject   : current user must be the offer's recipient.
//   withdraw : current user must be the offer's sender (you can only retract
//              your own offer, and only while it's still pending).
//
// All updates are gated on status = 'pending' with an affected_rows check so
// two racing requests can't both settle the same offer.
//
// Request (JSON):
//   { "offer_id": int, "user_id": int, "action": "accept"|"reject"|"withdraw" }
//
// Response (JSON):
//   { "success": true,
//     "data": {
//       "id": int,
//       "status": "accepted"|"rejected"|"withdrawn",
//       "superseded_count": int    // only nonzero for 'accept'
//     }
//   }

declare(strict_types=1);
require_once __DIR__ . '/api_helpers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body    = api_body();
$offerId = (int)($body['offer_id'] ?? 0);
$userId  = (int)($body['user_id'] ?? 0);
$action  = strtolower(trim((string)($body['action'] ?? '')));

if ($offerId <= 0 || $userId <= 0) {
    api_error('offer_id and user_id are required.', 400);
}
if (!in_array($action, ['accept', 'reject', 'withdraw'], true)) {
    api_error('action must be one of: accept, reject, withdraw.', 400);
}

// ---------------------------------------------------------------------------
// Load the offer and check authorization against the requested action.
// ---------------------------------------------------------------------------
$look = $conn->prepare(
    'SELECT id, listing_id, sender_id, recipient_id, status
     FROM offers WHERE id = ? LIMIT 1'
);
if (!$look) api_error('Server error.', 500);
$look->bind_param('i', $offerId);
$look->execute();
$offer = $look->get_result()->fetch_assoc();
$look->close();

if (!$offer) api_error('Offer not found.', 404);
if ($offer['status'] !== 'pending') {
    api_error('Offer is no longer pending (current status: ' . $offer['status'] . ').', 409);
}

if ($action === 'withdraw') {
    if ((int)$offer['sender_id'] !== $userId) {
        api_error('Only the sender of an offer can withdraw it.', 403);
    }
} else {
    // accept or reject
    if ((int)$offer['recipient_id'] !== $userId) {
        api_error('Only the recipient of an offer can ' . $action . ' it.', 403);
    }
}

$newStatus = [
    'accept'   => 'accepted',
    'reject'   => 'rejected',
    'withdraw' => 'withdrawn',
][$action];

$listingId  = (int)$offer['listing_id'];
$superseded = 0;

// ---------------------------------------------------------------------------
// Settle. The affected_rows=1 check on the primary update is what makes this
// race-safe: if two recipients tried to accept the same pending row, only
// one UPDATE will take effect; the loser rolls back with 409.
// ---------------------------------------------------------------------------
$conn->begin_transaction();
try {
    $upd = $conn->prepare(
        "UPDATE offers SET status = ?, responded_at = NOW()
         WHERE id = ? AND status = 'pending'"
    );
    if (!$upd) throw new RuntimeException('prepare(settle) failed: ' . $conn->error);
    $upd->bind_param('si', $newStatus, $offerId);
    if (!$upd->execute()) throw new RuntimeException('exec(settle) failed: ' . $upd->error);
    $affected = $upd->affected_rows;
    $upd->close();
    if ($affected !== 1) {
        $conn->rollback();
        api_error('Offer is no longer pending.', 409);
    }

    if ($action === 'accept') {
        // Any OTHER pending offers on this listing — from unrelated threads —
        // are now moot. We don't touch 'countered' rows (those are mid-thread
        // history) or anything already terminal.
        $sup = $conn->prepare(
            "UPDATE offers SET status = 'superseded', responded_at = NOW()
             WHERE listing_id = ? AND status = 'pending' AND id <> ?"
        );
        if (!$sup) throw new RuntimeException('prepare(supersede) failed: ' . $conn->error);
        $sup->bind_param('ii', $listingId, $offerId);
        if (!$sup->execute()) throw new RuntimeException('exec(supersede) failed: ' . $sup->error);
        $superseded = $sup->affected_rows;
        $sup->close();
    }

    $conn->commit();
} catch (Throwable $e) {
    $conn->rollback();
    error_log('respond_offer: ' . $e->getMessage());
    api_error('Failed to update offer.', 500);
}

api_success([
    'id'               => $offerId,
    'status'           => $newStatus,
    'superseded_count' => $superseded,
]);
