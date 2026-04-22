<?php
// make_offer.php — create a new offer (opener or counter).
//
// Two modes:
//
//   1. OPENER  (no parent_offer_id)
//      sender_id    = the buyer
//      recipient_id = the seller (listing owner), passed by the client
//      amount       = buyer's proposed price
//      note         = optional free text, encrypted at rest
//
//   2. COUNTER (parent_offer_id set)
//      sender_id    = current user (must be the recipient of the parent)
//      recipient_id = derived server-side from the parent's sender
//      The parent row is transactionally moved from 'pending' to 'countered'
//      in the same transaction as the new row's INSERT.
//
// Request (JSON):
//   { "listing_id": int, "sender_id": int,
//     "recipient_id": int,     // required for openers; ignored for counters
//     "amount": number,
//     "note": string?,
//     "parent_offer_id": int? }

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
    function api_body(): array { $raw = file_get_contents('php://input'); if ($raw === false || $raw === '') return []; $decoded = json_decode($raw, true); return is_array($decoded) ? $decoded : []; }
}

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
// DECIMAL(10,2) can hold up to 99,999,999.99; cap lower to reject garbage.
if ($amount <= 0 || $amount > 9999999.99) {
    api_error('amount must be greater than 0 and at most 9,999,999.99.', 400);
}
$amount = round($amount, 2);

// Resolve recipient. For a counter, look up the parent and validate:
//   (a) same listing
//   (b) still pending
//   (c) current sender is the parent's recipient
// The new counter's recipient is the parent's sender (sides flip).
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

// Transactional write. A counter needs two rows to move together (parent ->
// countered, new row -> pending); the affected_rows check on the parent
// update detects the race where something else settled the parent between
// our SELECT above and this UPDATE.
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

    // parent_offer_id may be NULL. mysqli::bind_param accepts a null variable
    // under 'i' and sends SQL NULL, so a single bind handles both cases.
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
