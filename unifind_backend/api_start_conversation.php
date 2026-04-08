<?php
/**
 * api_start_conversation.php  →  upload as: start_conversation.php
 *
 * Finds or creates a conversation between two users about a listing or a
 * lost & found item. Idempotent — calling it twice returns the same row.
 *
 * POST start_conversation.php
 * Body (JSON):
 *   {
 *     "listing_id": 5,        <- the item/post ID (marketplace or lost_found_items)
 *     "user1_id":   123,      <- initiator (buyer / claimant / finder)
 *     "user2_id":   456,      <- responder (seller / poster)
 *     "subject":    "Lost & Found: Blue Umbrella"
 *   }
 */

declare(strict_types=1);

require_once __DIR__ . '/api_helpers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error('Method not allowed.', 405);
}

$body      = api_body();
$listingId = (int)($body['listing_id'] ?? 0);
$user1Id   = (int)($body['user1_id']   ?? 0);
$user2Id   = (int)($body['user2_id']   ?? 0);
$subject   = trim((string)($body['subject'] ?? ''));

if ($user1Id  <= 0) api_error('user1_id is required.', 400, 'MISSING_FIELD');
if ($user2Id  <= 0) api_error('user2_id is required.', 400, 'MISSING_FIELD');
if ($user1Id === $user2Id) api_error('Cannot start a conversation with yourself.', 400, 'SELF_MESSAGE');
if ($subject  === '') $subject = 'New conversation';

$listingIdOrNull = $listingId > 0 ? $listingId : null;

// ── Look for an existing conversation ────────────────────────────────────────
if ($listingIdOrNull !== null) {
    $find = $conn->prepare(
        'SELECT id FROM conversations
         WHERE listing_id = ?
           AND ((user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?))
         LIMIT 1'
    );
    if (!$find) api_error('Server error.', 500);
    $find->bind_param('iiiii', $listingIdOrNull, $user1Id, $user2Id, $user2Id, $user1Id);
} else {
    $find = $conn->prepare(
        'SELECT id FROM conversations
         WHERE listing_id IS NULL
           AND ((user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?))
         LIMIT 1'
    );
    if (!$find) api_error('Server error.', 500);
    $find->bind_param('iiii', $user1Id, $user2Id, $user2Id, $user1Id);
}

$find->execute();
$existing = $find->get_result()->fetch_assoc();
$find->close();

// Already exists — return it immediately, no duplicate created
if ($existing) {
    api_success(['id' => (int)$existing['id'], 'is_new' => false]);
}

// ── Create new conversation ───────────────────────────────────────────────────
if ($listingIdOrNull !== null) {
    $ins = $conn->prepare(
        'INSERT INTO conversations (listing_id, user1_id, user2_id, subject, created_at)
         VALUES (?, ?, ?, ?, NOW())'
    );
    if (!$ins) api_error('Server error preparing insert.', 500);
    $ins->bind_param('iiis', $listingIdOrNull, $user1Id, $user2Id, $subject);
} else {
    $ins = $conn->prepare(
        'INSERT INTO conversations (listing_id, user1_id, user2_id, subject, created_at)
         VALUES (NULL, ?, ?, ?, NOW())'
    );
    if (!$ins) api_error('Server error preparing insert.', 500);
    $ins->bind_param('iis', $user1Id, $user2Id, $subject);
}

if (!$ins->execute()) {
    error_log('start_conversation insert error: ' . $ins->error);
    $ins->close();
    api_error('Could not create conversation. Please try again.', 500);
}

$convId = (int)$ins->insert_id;
$ins->close();

// ── Auto-insert opening message ───────────────────────────────────────────────
// Try to resolve the item name from marketplace_items first,
// then fall back to lost_found_items — these are the actual table names
// in the ivanovs1_UniFind_Test database.
$itemName = '';
if ($listingIdOrNull !== null) {
    // Try marketplace_items
    $ls = $conn->prepare('SELECT title FROM marketplace_items WHERE id = ? LIMIT 1');
    if ($ls) {
        $ls->bind_param('i', $listingIdOrNull);
        $ls->execute();
        $lRow = $ls->get_result()->fetch_assoc();
        $ls->close();
        $itemName = $lRow ? (string)$lRow['title'] : '';
    }

    // If not found in marketplace, try lost_found_items
    if ($itemName === '') {
        $ls2 = $conn->prepare('SELECT title FROM lost_found_items WHERE id = ? LIMIT 1');
        if ($ls2) {
            $ls2->bind_param('i', $listingIdOrNull);
            $ls2->execute();
            $lRow2 = $ls2->get_result()->fetch_assoc();
            $ls2->close();
            $itemName = $lRow2 ? (string)$lRow2['title'] : '';
        }
    }
}

$opener = $itemName !== ''
    ? 'Hi! I wanted to reach out about "' . $itemName . '". Can we arrange a time to meet?'
    : 'Hi! I wanted to reach out about your post. Can we arrange a time to meet?';

$mIns = $conn->prepare(
    'INSERT INTO messages (conversation_id, sender_id, body, is_read, sent_at)
     VALUES (?, ?, ?, 0, NOW())'
);
if ($mIns) {
    $mIns->bind_param('iis', $convId, $user1Id, $opener);
    $mIns->execute();
    $mIns->close();
}

api_success(['id' => $convId, 'is_new' => true]);
