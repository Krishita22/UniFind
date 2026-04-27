<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$claimId = (int)($body['claim_id'] ?? 0);

if ($claimId <= 0) api_error('claim_id required.', 400);

// Get claim details and conversation_id
$claimStmt = $conn->prepare("
    SELECT c.id, c.claimant_id, c.found_item_id, c.status,
           u.email as claimant_email, u.username as claimant_username,
           lf.title as item_title, lf.poster_id as finder_id,
           conv.id as conversation_id
    FROM lost_found_claims c
    JOIN users u ON c.claimant_id = u.id
    JOIN lost_found_items lf ON c.found_item_id = lf.id
    LEFT JOIN conversations conv ON conv.listing_id = c.id
    WHERE c.id = ? LIMIT 1
");
if (!$claimStmt) api_error('Prepare error: ' . $conn->error, 500);
$claimStmt->bind_param('i', $claimId);
if (!$claimStmt->execute()) api_error('Execute error: ' . $claimStmt->error, 500);
$claim = $claimStmt->get_result()->fetch_assoc();
$claimStmt->close();

if (!$claim) api_error('Claim not found.', 404);

// Create conversation if it doesn't exist
if (!$claim['conversation_id']) {
    $convId = null;
    $subject = "Claim: " . $claim['item_title'];

    // Check if conversation already exists
    $existConv = $conn->prepare(
        'SELECT id FROM conversations WHERE listing_id = ? AND ((user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)) LIMIT 1'
    );
    if ($existConv) {
        $existConv->bind_param('iiiii', $claimId, $claim['claimant_id'], $claim['finder_id'], $claim['finder_id'], $claim['claimant_id']);
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
            $convIns->bind_param('iiis', $claimId, $claim['claimant_id'], $claim['finder_id'], $subject);
            if ($convIns->execute()) $convId = (int)$convIns->insert_id;
            $convIns->close();
        }

        // Opening message
        if ($convId !== null) {
            $opener = "Your claim for \"" . $claim['item_title'] . "\" has been approved! You can now coordinate meetup details here.";
            $msgIns = $conn->prepare(
                'INSERT INTO messages (conversation_id, sender_id, body, is_read, sent_at) VALUES (?, ?, ?, 0, NOW())'
            );
            if ($msgIns) {
                $msgIns->bind_param('iis', $convId, $claim['claimant_id'], $opener);
                $msgIns->execute();
                $msgIns->close();
            }
        }
    }

    $claim['conversation_id'] = $convId;
}

// Record approval in claim_approvals
$approvalStmt = $conn->prepare("
    INSERT INTO claim_approvals (claim_id, status, approved_at)
    VALUES (?, 'approved', NOW())
");
if (!$approvalStmt) api_error('Approval insert prepare: ' . $conn->error, 500);
$approvalStmt->bind_param('i', $claimId);
if (!$approvalStmt->execute()) api_error('Approval insert execute: ' . $approvalStmt->error, 500);
$approvalStmt->close();

// Update claim status
$updateStmt = $conn->prepare("UPDATE lost_found_claims SET status = 'approved' WHERE id = ?");
if (!$updateStmt) api_error('Update prepare: ' . $conn->error, 500);
$updateStmt->bind_param('i', $claimId);
if (!$updateStmt->execute()) api_error('Update execute: ' . $updateStmt->error, 500);
$updateStmt->close();

// Send email to claimant
$subject = 'Your Claim Has Been Approved';
$body = "Hi {$claim['claimant_username']},\n\nYour claim for the item '{$claim['item_title']}' has been approved!\n\nYou can now propose a meetup time and location with the item finder.\n\nBest regards,\nUniFind Team";
$headers = "From: UniFind <unifind@ivanovs1.nodomain>\r\n";
@mail($claim['claimant_email'], $subject, $body, $headers);

api_success([
    'claim_id' => $claimId,
    'status' => 'approved',
    'conversation_id' => $claim['conversation_id']
]);
?>
