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
$meetupDate = (string)($body['meetup_date'] ?? '');
$meetupTime = (string)($body['meetup_time'] ?? '');
$meetupLocation = (string)($body['meetup_location'] ?? '');

if ($claimId <= 0) api_error('claim_id required.', 400);
if (empty($meetupDate) || empty($meetupTime) || empty($meetupLocation)) api_error('meetup_date, meetup_time, and meetup_location required.', 400);

// Validate date/time format
if (!strtotime($meetupDate)) api_error('Invalid meetup_date format.', 400);
if (!strtotime($meetupTime)) api_error('Invalid meetup_time format.', 400);

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

// Get found item details to get the finder's ID
$itemStmt = $conn->prepare("SELECT poster_id, title FROM lost_found_items WHERE id = ? LIMIT 1");
if (!$itemStmt) api_error('Item prepare error: ' . $conn->error, 500);
$itemStmt->bind_param('i', $claim['found_item_id']);
if (!$itemStmt->execute()) api_error('Item execute error: ' . $itemStmt->error, 500);
$item = $itemStmt->get_result()->fetch_assoc();
$itemStmt->close();

if (!$item) api_error('Found item not found.', 404);

$finderId = $item['poster_id'];
$claimantId = $claim['claimant_id'];
$itemTitle = $item['title'];

// Get the lost item posted by the claimant
$claimantLostItemStmt = $conn->prepare("
    SELECT id FROM lost_found_items
    WHERE poster_id = ? AND type = 'lost'
    ORDER BY created_at DESC
    LIMIT 1
");
if (!$claimantLostItemStmt) api_error('Get claimant lost item error: ' . $conn->error, 500);
$claimantLostItemStmt->bind_param('i', $claimantId);
if (!$claimantLostItemStmt->execute()) api_error('Get claimant lost item execute error: ' . $claimantLostItemStmt->error, 500);
$claimantLostResult = $claimantLostItemStmt->get_result()->fetch_assoc();
$claimantLostItemStmt->close();

$lostItemId = $claimantLostResult ? (int)$claimantLostResult['id'] : 0;
if ($lostItemId <= 0) api_error('Lost item not found for claimant.', 404);

// Create a match between the lost and found items
$matchStmt = $conn->prepare("
    INSERT INTO lost_found_matches (lost_item_id, matched_found_item_id, submitted_by, status)
    VALUES (?, ?, ?, 'pending')
");
if (!$matchStmt) api_error('Match insert prepare error: ' . $conn->error, 500);
$matchStmt->bind_param('iii', $lostItemId, $claim['found_item_id'], $claimantId);
if (!$matchStmt->execute()) api_error('Match insert execute error: ' . $matchStmt->error, 500);
$matchId = $conn->insert_id;
$matchStmt->close();

// Create the meetup
$meetupStmt = $conn->prepare("
    INSERT INTO lost_found_meetups (match_id, meetup_date, meetup_time, meetup_location, status)
    VALUES (?, ?, ?, ?, 'pending')
");
if (!$meetupStmt) api_error('Meetup insert prepare error: ' . $conn->error, 500);
$meetupStmt->bind_param('isss', $matchId, $meetupDate, $meetupTime, $meetupLocation);
if (!$meetupStmt->execute()) api_error('Meetup insert execute error: ' . $meetupStmt->error, 500);
$meetupId = $conn->insert_id;
$meetupStmt->close();

// Send notification to both users that meetup was proposed
$claimantStmt = $conn->prepare("SELECT email, username FROM users WHERE id = ?");
$claimantStmt->bind_param('i', $claimantId);
$claimantStmt->execute();
$claimant = $claimantStmt->get_result()->fetch_assoc();
$claimantStmt->close();

$finderStmt = $conn->prepare("SELECT email, username FROM users WHERE id = ?");
$finderStmt->bind_param('i', $finderId);
$finderStmt->execute();
$finder = $finderStmt->get_result()->fetch_assoc();
$finderStmt->close();

// Email to claimant: meetup proposed (waiting for admin approval)
$subject = 'Meetup Proposed for Your Claim';
$body = "Hi {$claimant['username']},\n\nYou have proposed a meetup for your claim on '{$itemTitle}'. The meetup details are:\n\nDate: {$meetupDate}\nTime: {$meetupTime}\nLocation: {$meetupLocation}\n\nThe meetup is pending admin approval. You'll be notified once it's approved.\n\nBest regards,\nUniFind Team";
$headers = "From: UniFind <unifind@ivanovs1.nodomain>\r\n";
@mail($claimant['email'], $subject, $body, $headers);

// Email to finder: meetup proposed by claimant
$subject = 'Meetup Proposed for Your Found Item';
$body = "Hi {$finder['username']},\n\n{$claimant['username']} has proposed a meetup for your found item '{$itemTitle}'. The meetup details are:\n\nDate: {$meetupDate}\nTime: {$meetupTime}\nLocation: {$meetupLocation}\n\nThe meetup is pending admin approval. You'll be notified once it's approved.\n\nBest regards,\nUniFind Team";
@mail($finder['email'], $subject, $body, $headers);

api_success([
    'meetup_id' => $meetupId,
    'match_id' => $matchId,
    'claim_id' => $claimId,
    'status' => 'pending'
]);
?>
