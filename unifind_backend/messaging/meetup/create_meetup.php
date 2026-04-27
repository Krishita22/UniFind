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
$itemId = (int)($body['item_id'] ?? 0);
$claimId = (int)($body['claim_id'] ?? 0);
$conversationId = (int)($body['conversation_id'] ?? 0);
$buyerId = (int)($body['buyer_id'] ?? 0);
$sellerId = (int)($body['seller_id'] ?? 0);
$date = (string)($body['meetup_date'] ?? '');
$time = (string)($body['meetup_time'] ?? '');
$location = (string)($body['meetup_location'] ?? '');

if (empty($date) || empty($time) || empty($location)) api_error('meetup_date, meetup_time, and meetup_location required.', 400);

if ($itemId > 0) {
    // MARKETPLACE MEETUP
    if ($conversationId <= 0 || $buyerId <= 0 || $sellerId <= 0) api_error('For marketplace meetups: conversation_id, buyer_id, seller_id required.', 400);

    // Create marketplace meetup
    $stmt = $conn->prepare("
        INSERT INTO meetups (item_id, buyer_id, seller_id, meetup_date, meetup_time, location, status)
        VALUES (?, ?, ?, ?, ?, ?, 'user_pending')
    ");
    if (!$stmt) api_error('Prepare error: ' . $conn->error, 500);
    $stmt->bind_param('iiisss', $itemId, $buyerId, $sellerId, $date, $time, $location);
    if (!$stmt->execute()) api_error('Execute error: ' . $stmt->error, 500);
    $meetupId = $conn->insert_id;
    $stmt->close();

    api_success(['meetup_id' => $meetupId, 'type' => 'marketplace']);

} elseif ($claimId > 0) {
    // LOST & FOUND MEETUP

    // Verify claim exists and is approved
    $claimStmt = $conn->prepare("
        SELECT c.id, c.found_item_id, c.claimant_id, ca.status as claim_status
        FROM lost_found_claims c
        LEFT JOIN claim_approvals ca ON c.id = ca.claim_id AND ca.status = 'approved'
        WHERE c.id = ? LIMIT 1
    ");
    if (!$claimStmt) api_error('Prepare error: ' . $conn->error, 500);
    $claimStmt->bind_param('i', $claimId);
    if (!$claimStmt->execute()) api_error('Execute error: ' . $claimStmt->error, 500);
    $claim = $claimStmt->get_result()->fetch_assoc();
    $claimStmt->close();

    if (!$claim) api_error('Claim not found.', 404);
    if ($claim['claim_status'] !== 'approved') api_error('Claim must be approved before proposing meetup.', 400);

    // Get found item details
    $itemStmt = $conn->prepare("SELECT poster_id FROM lost_found_items WHERE id = ? LIMIT 1");
    if (!$itemStmt) api_error('Item prepare error: ' . $conn->error, 500);
    $itemStmt->bind_param('i', $claim['found_item_id']);
    if (!$itemStmt->execute()) api_error('Item execute error: ' . $itemStmt->error, 500);
    $item = $itemStmt->get_result()->fetch_assoc();
    $itemStmt->close();

    if (!$item) api_error('Found item not found.', 404);

    $finderId = $item['poster_id'];
    $claimantId = $claim['claimant_id'];

    // Get claimant's lost item
    $lostStmt = $conn->prepare("
        SELECT id FROM lost_found_items
        WHERE poster_id = ? AND type = 'lost'
        ORDER BY created_at DESC
        LIMIT 1
    ");
    if (!$lostStmt) api_error('Lost item prepare error: ' . $conn->error, 500);
    $lostStmt->bind_param('i', $claimantId);
    if (!$lostStmt->execute()) api_error('Lost item execute error: ' . $lostStmt->error, 500);
    $lost = $lostStmt->get_result()->fetch_assoc();
    $lostStmt->close();

    $lostItemId = $lost ? (int)$lost['id'] : 0;
    if ($lostItemId <= 0) api_error('Lost item not found for claimant.', 404);

    // Create match
    $matchStmt = $conn->prepare("
        INSERT INTO lost_found_matches (lost_item_id, matched_found_item_id, submitted_by, status, found_location, found_when, match_details)
        VALUES (?, ?, ?, 'pending', '', '', '')
    ");
    if (!$matchStmt) api_error('Match prepare error: ' . $conn->error, 500);
    $matchStmt->bind_param('iii', $lostItemId, $claim['found_item_id'], $claimantId);
    if (!$matchStmt->execute()) api_error('Match execute error: ' . $matchStmt->error, 500);
    $matchId = $conn->insert_id;
    $matchStmt->close();

    // Create meetup
    $meetupStmt = $conn->prepare("
        INSERT INTO lost_found_meetups (match_id, meetup_date, meetup_time, meetup_location, status)
        VALUES (?, ?, ?, ?, 'user_pending')
    ");
    if (!$meetupStmt) api_error('Meetup prepare error: ' . $conn->error, 500);
    $meetupStmt->bind_param('isss', $matchId, $date, $time, $location);
    if (!$meetupStmt->execute()) api_error('Meetup execute error: ' . $meetupStmt->error, 500);
    $meetupId = $conn->insert_id;
    $meetupStmt->close();

    api_success(['meetup_id' => $meetupId, 'match_id' => $matchId, 'type' => 'lost_found']);

} else {
    api_error('Either item_id (marketplace) or claim_id (lost_found) required.', 400);
}
?>
