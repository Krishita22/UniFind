<?php
declare(strict_types=1);
require_once __DIR__ . '/../api_helpers.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body       = api_body();
$lostItemId  = (int)($body['lost_item_id'] ?? 0);
$foundItemId = (int)($body['found_item_id'] ?? 0);

if ($lostItemId <= 0) api_error('lost_item_id required.', 400);
if ($foundItemId <= 0) api_error('found_item_id required.', 400);

// Verify both items exist
$lStmt = $conn->prepare('SELECT id, user_id, title FROM lost_found_items WHERE id = ? LIMIT 1');
$lStmt->bind_param('i', $lostItemId);
$lStmt->execute();
$lostItem = $lStmt->get_result()->fetch_assoc();
$lStmt->close();
if (!$lostItem) api_error('Lost item not found.', 404);

$fStmt = $conn->prepare('SELECT id, user_id, title FROM lost_found_items WHERE id = ? LIMIT 1');
$fStmt->bind_param('i', $foundItemId);
$fStmt->execute();
$foundItem = $fStmt->get_result()->fetch_assoc();
$fStmt->close();
if (!$foundItem) api_error('Found item not found.', 404);

// Create the match
$ins = $conn->prepare(
    'INSERT INTO lost_found_matches (lost_item_id, found_item_id, status, created_at) VALUES (?, ?, "active", NOW())'
);
if (!$ins) api_error('Server error.', 500);
$ins->bind_param('ii', $lostItemId, $foundItemId);
if (!$ins->execute()) api_error('Failed to create match.', 500);
$matchId = (int)$ins->insert_id;
$ins->close();

// Mark both items as matched
$upd = $conn->prepare('UPDATE lost_found_items SET status = "matched" WHERE id IN (?, ?)');
if ($upd) {
    $upd->bind_param('ii', $lostItemId, $foundItemId);
    $upd->execute();
    $upd->close();
}

// Start a conversation between the two item posters
$lostPosterId  = (int)$lostItem['user_id'];
$foundPosterId = (int)$foundItem['user_id'];

if ($lostPosterId !== $foundPosterId) {
    $subject = "Match: " . $lostItem['title'] . " & " . $foundItem['title'];
    // Check if conversation already exists
    $existConv = $conn->prepare(
        'SELECT id FROM conversations WHERE listing_id = ? AND ((user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)) LIMIT 1'
    );
    $convId = null;
    if ($existConv) {
        $existConv->bind_param('iiiii', $matchId, $lostPosterId, $foundPosterId, $foundPosterId, $lostPosterId);
        $existConv->execute();
        $existRow = $existConv->get_result()->fetch_assoc();
        $existConv->close();
        if ($existRow) $convId = (int)$existRow['id'];
    }

    if ($convId === null) {
        $convIns = $conn->prepare(
            'INSERT INTO conversations (listing_id, user1_id, user2_id, subject, created_at) VALUES (?, ?, ?, ?, NOW())'
        );
        if ($convIns) {
            $convIns->bind_param('iiis', $matchId, $lostPosterId, $foundPosterId, $subject);
            if ($convIns->execute()) $convId = (int)$convIns->insert_id;
            $convIns->close();
        }

        // Opening message
        if ($convId !== null) {
            $opener = "An admin has matched your items! \"" . $lostItem['title'] . "\" and \"" . $foundItem['title'] . "\" appear to be a match. Please coordinate pickup/return details here.";
            $msgIns = $conn->prepare(
                'INSERT INTO messages (conversation_id, sender_id, body, is_read, sent_at) VALUES (?, ?, ?, 0, NOW())'
            );
            if ($msgIns) {
                $msgIns->bind_param('iis', $convId, $lostPosterId, $opener);
                $msgIns->execute();
                $msgIns->close();
            }
        }
    }
}

api_success(['match_id' => $matchId]);
