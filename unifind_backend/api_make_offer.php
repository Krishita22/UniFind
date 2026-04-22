<?php
// upload as: make_offer.php
//
// Create a new offer on a marketplace listing.
//
// Two modes, distinguished by presence of parent_offer_id:
//
//   1. OPENER (no parent_offer_id)
//      - sender_id      = the buyer
//      - recipient_id   = the seller (listing owner), passed by the client
//      - amount         = buyer's proposed price
//      - note           = optional free-text message (encrypted at rest)
//
//   2. COUNTER (parent_offer_id set)
//      - sender_id      = current user (must be recipient of the parent)
//      - recipient_id   = derived server-side from the parent's sender
//      - amount         = counter price
//      - The parent row is transactionally moved from 'pending' to 'countered'
//        in the same transaction as the new row's INSERT. If a concurrent
//        respond_offer.php already settled the parent, the UPDATE affects
//        zero rows and we abort with 409 instead of orphaning a counter.
//
// Request (JSON):
//   {
//     "listing_id":       int,          // required
//     "sender_id":        int,          // required
//     "recipient_id":     int,          // required for openers; ignored for counters
//     "amount":           number,       // required, > 0, <= 9,999,999.99
//     "note":             string?,      // optional, encrypted at rest
//     "parent_offer_id":  int?          // optional; if set this is a counter
//   }
//
// Response (JSON):
//   { "success": true,
//     "data": {
//       "id": int,
//       "status": "pending",
//       "parent_offer_id": int|null,
//       "recipient_id": int
//     }
//   }

declare(strict_types=1);
require_once __DIR__ . '/api_helpers.php';
require_once __DIR__ . '/includes/crypto.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body        = api_body();
$listingId   = (int)($body['listing_id'] ?? 0);
$senderId    = (int)($body['sender_id'] ?? 0);
$recipientId = (int)($body['recipient_id'] ?? 0);
$amountRaw   = $body['amount'] ?? null;
$note        = trim((string)($body['note'] ?? ''));
$parentId    = (int)($body['parent_offer_id'] ?? 0);

if ($listingId <= 0 || $senderId <= 0) {
    api_error('listing_id and sender_id are required.', 400);
}
if (!is_numeric($amountRaw)) {
    api_error('amount is required and must be numeric.', 400);
}
$amount = (float)$amountRaw;
// DECIMAL(10,2) can hold up to 99,999,999.99, but we cap lower to leave
// headroom and reject obviously-garbage inputs early.
if ($amount <= 0 || $amount > 9999999.99) {
    api_error('amount must be greater than 0 and at most 9,999,999.99.', 400);
}
// Snap to 2 decimal places to avoid silent rounding surprises when stored.
$amount = round($amount, 2);

// ---------------------------------------------------------------------------
// Resolve recipient. For a counter, we look up the parent and validate that
// (a) it refers to the same listing, (b) it is still pending, and (c) the
// current sender is its recipient. The recipient of the new counter is the
// parent's sender (the sides flip).
// ---------------------------------------------------------------------------
if ($parentId > 0) {
    $stmtP = $conn->prepare(
        'SELECT id, listing_id, sender_id, recipient_id, status
         FROM offers WHERE id = ? LIMIT 1'
    );
    if (!$stmtP) api_error('Server error.', 500);
    $stmtP->bind_param('i', $parentId);
    $stmtP->execute();
    $parent = $stmtP->get_result()->fetch_assoc();
    $stmtP->close();

    if (!$parent)                                           api_error('Parent offer not found.', 404);
    if ((int)$parent['listing_id'] !== $listingId)          api_error('Parent offer is for a different listing.', 400);
    if ($parent['status'] !== 'pending')                    api_error('Parent offer is no longer pending.', 409);
    if ((int)$parent['recipient_id'] !== $senderId)         api_error('Only the recipient of an offer can counter it.', 403);

    $recipientId = (int)$parent['sender_id'];
} else {
    // Opener: client must tell us who the seller is. Matches the pattern used
    // by api_start_conversation.php (both user1_id and user2_id in the body).
    if ($recipientId <= 0) api_error('recipient_id is required for a new offer.', 400);
    if ($recipientId === $senderId) api_error('You cannot make an offer to yourself.', 400);
}

// Encrypt the note if present. NULL/empty stays NULL so reads don't need to
// branch on sentinel values — decrypt_message_body passes NULL through.
$storedNote = null;
if ($note !== '') {
    try {
        $storedNote = encrypt_message_body($note);
    } catch (Throwable $e) {
        error_log('make_offer encrypt note: ' . $e->getMessage());
        api_error('Server error.', 500);
    }
}

// ---------------------------------------------------------------------------
// Write. A counter needs two rows to move together (parent -> countered, new
// row -> pending); wrap in a transaction and use affected_rows on the parent
// update to detect the race where something else settled it between our
// SELECT above and the UPDATE here.
// ---------------------------------------------------------------------------
$conn->begin_transaction();
try {
    if ($parentId > 0) {
        $upd = $conn->prepare(
            "UPDATE offers SET status = 'countered', responded_at = NOW()
             WHERE id = ? AND status = 'pending'"
        );
        if (!$upd) throw new RuntimeException('prepare(parent update) failed: ' . $conn->error);
        $upd->bind_param('i', $parentId);
        if (!$upd->execute()) throw new RuntimeException('exec(parent update) failed: ' . $upd->error);
        $affected = $upd->affected_rows;
        $upd->close();
        if ($affected !== 1) {
            $conn->rollback();
            api_error('Parent offer is no longer pending.', 409);
        }
    }

    $ins = $conn->prepare(
        'INSERT INTO offers
           (listing_id, sender_id, recipient_id, amount, status, parent_offer_id, note, created_at)
         VALUES (?, ?, ?, ?, \'pending\', ?, ?, NOW())'
    );
    if (!$ins) throw new RuntimeException('prepare(insert) failed: ' . $conn->error);

    // parent_offer_id may be NULL. mysqli_stmt::bind_param accepts a null
    // variable under the 'i' specifier and sends SQL NULL, so a single bind
    // handles both opener (parentBind = null) and counter (parentBind = int).
    $parentBind = $parentId > 0 ? $parentId : null;
    $ins->bind_param('iiidis', $listingId, $senderId, $recipientId, $amount, $parentBind, $storedNote);
    if (!$ins->execute()) throw new RuntimeException('exec(insert) failed: ' . $ins->error);
    $newId = (int)$ins->insert_id;
    $ins->close();

    $conn->commit();
} catch (Throwable $e) {
    $conn->rollback();
    error_log('make_offer: ' . $e->getMessage());
    api_error('Failed to create offer.', 500);
}

api_success([
    'id'              => $newId,
    'status'          => 'pending',
    'parent_offer_id' => $parentId > 0 ? $parentId : null,
    'recipient_id'    => $recipientId,
]);
