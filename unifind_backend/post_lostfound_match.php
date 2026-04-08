<?php
declare(strict_types=1);
require_once __DIR__ . '/api_helpers.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body = api_body();
$lostItemId    = (int)($body['lost_item_id'] ?? 0);
$email         = trim((string)($body['email'] ?? ''));
$foundLocation = trim((string)($body['found_location'] ?? ''));
$foundWhen     = trim((string)($body['found_when'] ?? ''));
$matchDetails  = trim((string)($body['match_details'] ?? ''));
$contactNote   = trim((string)($body['contact_note'] ?? ''));

if ($lostItemId <= 0) api_error('lost_item_id required.', 400);
if ($email === '') api_error('email required.', 400);
if ($foundLocation === '') api_error('found_location required.', 400);
if ($matchDetails === '') api_error('match_details required.', 400);

// Look up user by email
$uStmt = $conn->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
if (!$uStmt) api_error('Server error.', 500);
$uStmt->bind_param('s', $email);
$uStmt->execute();
$uRow = $uStmt->get_result()->fetch_assoc();
$uStmt->close();
if (!$uRow) api_error('User not found.', 404);
$submitterId = (int)$uRow['id'];

// Verify item exists
$iStmt = $conn->prepare('SELECT id FROM lost_found_items WHERE id = ? LIMIT 1');
if (!$iStmt) api_error('Server error.', 500);
$iStmt->bind_param('i', $lostItemId);
$iStmt->execute();
$iRow = $iStmt->get_result()->fetch_assoc();
$iStmt->close();
if (!$iRow) api_error('Item not found.', 404);

// Insert match submission
$ins = $conn->prepare(
    'INSERT INTO lost_found_matches (lost_item_id, submitter_id, found_location, found_when, match_details, contact_note, status, created_at)
     VALUES (?, ?, ?, ?, ?, ?, "active", NOW())'
);
if (!$ins) api_error('Server error.', 500);
$ins->bind_param('iissss', $lostItemId, $submitterId, $foundLocation, $foundWhen, $matchDetails, $contactNote);
if (!$ins->execute()) {
    api_error('Failed to submit match.', 500);
}
$matchId = (int)$ins->insert_id;
$ins->close();

api_success(['match_id' => $matchId]);
