<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) {
        header('Content-Type: application/json');
        echo json_encode(['success' => true, 'data' => $data]);
        exit;
    }
    function api_error(string $message, int $status = 400) {
        http_response_code($status);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'error' => $message]);
        exit;
    }
    function api_body(): array {
        $raw = file_get_contents('php://input');
        if ($raw === false || $raw === '') return [];
        $decoded = json_decode($raw, true);
        return is_array($decoded) ? $decoded : [];
    }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body    = api_body();
$claimId = (int)($body['claim_id'] ?? 0);
$itemId  = (int)($body['item_id'] ?? 0);

if ($claimId <= 0) api_error('claim_id required.', 400);
if ($itemId <= 0) api_error('item_id required.', 400);

// Verify claim exists and is pending
$cStmt = $conn->prepare('SELECT id, claimant_id, status FROM lost_found_claims WHERE id = ? AND found_item_id = ? LIMIT 1');
if (!$cStmt) api_error('Server error.', 500);
$cStmt->bind_param('ii', $claimId, $itemId);
$cStmt->execute();
$claim = $cStmt->get_result()->fetch_assoc();
$cStmt->close();
if (!$claim) api_error('Claim not found.', 404);
if ($claim['status'] !== 'pending') api_error('Claim already processed.', 400);

$claimantId = (int)$claim['claimant_id'];

// Get the item poster's user ID
$iStmt = $conn->prepare('SELECT poster_id, title FROM lost_found_items WHERE id = ? LIMIT 1');
if (!$iStmt) api_error('Server error.', 500);
$iStmt->bind_param('i', $itemId);
$iStmt->execute();
$item = $iStmt->get_result()->fetch_assoc();
$iStmt->close();
if (!$item) api_error('Item not found.', 404);
$posterId = (int)$item['poster_id'];
$itemTitle = $item['title'];

// Update claim status to approved
$upd = $conn->prepare('UPDATE lost_found_claims SET status = "approved" WHERE id = ?');
if (!$upd) api_error('Server error.', 500);
$upd->bind_param('i', $claimId);
if (!$upd->execute()) api_error('Failed to approve claim.', 500);
$upd->close();

// Reject all other pending claims for the same item
$rej = $conn->prepare('UPDATE lost_found_claims SET status = "rejected" WHERE found_item_id = ? AND id != ? AND status = "pending"');
if ($rej) {
    $rej->bind_param('ii', $itemId, $claimId);
    $rej->execute();
    $rej->close();
}

// Start a conversation between the claimant and the poster so they can chat
if ($claimantId !== $posterId) {
    // Check if a conversation already exists between these two about this item
    $existConv = $conn->prepare(
        'SELECT id FROM conversations WHERE listing_id = ? AND ((user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)) LIMIT 1'
    );
    $convId = null;
    if ($existConv) {
        $existConv->bind_param('iiiii', $itemId, $claimantId, $posterId, $posterId, $claimantId);
        $existConv->execute();
        $existRow = $existConv->get_result()->fetch_assoc();
        $existConv->close();
        if ($existRow) {
            $convId = (int)$existRow['id'];
        }
    }

    if ($convId === null) {
        // Create new conversation
        $subject = "Claim Approved: $itemTitle";
        $convIns = $conn->prepare(
            'INSERT INTO conversations (listing_id, user1_id, user2_id, subject, created_at) VALUES (?, ?, ?, ?, NOW())'
        );
        if ($convIns) {
            $convIns->bind_param('iiis', $itemId, $claimantId, $posterId, $subject);
            if ($convIns->execute()) {
                $convId = (int)$convIns->insert_id;
            }
            $convIns->close();
        }
    }

    // Send an automatic opening message
    if ($convId !== null) {
        $opener = "Your claim for \"$itemTitle\" has been approved by an admin! You can now coordinate pickup/return details here.";
        $msgIns = $conn->prepare(
            'INSERT INTO messages (conversation_id, sender_id, body, is_read, sent_at) VALUES (?, ?, ?, 0, NOW())'
        );
        if ($msgIns) {
            $msgIns->bind_param('iis', $convId, $claimantId, $opener);
            $msgIns->execute();
            $msgIns->close();
        }
    }
}

api_success(['claim_id' => $claimId, 'status' => 'approved', 'conversation_id' => $convId]);
