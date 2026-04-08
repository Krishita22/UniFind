<?php
/**
 * api_submit_rating.php  →  upload as: submit_rating.php
 *
 * Submits a star rating from one user to another after an interaction completes.
 * Each pair of users can only rate each other once per conversation.
 *
 * POST submit_rating.php
 * Body (JSON):
 *   {
 *     "conversation_id": 1,
 *     "rater_id":        123,   <- user submitting the rating
 *     "target_id":       456,   <- user being rated
 *     "stars":           5,     <- 1 to 5
 *     "comment":         "Great experience!"  <- optional
 *   }
 */

declare(strict_types=1);

require_once __DIR__ . '/api_helpers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error('Method not allowed.', 405);
}

$body           = api_body();
$conversationId = (int)($body['conversation_id'] ?? 0);
$raterId        = (int)($body['rater_id']        ?? 0);
$targetId       = (int)($body['target_id']       ?? 0);
$stars          = (int)($body['stars']           ?? 0);
$comment        = trim((string)($body['comment'] ?? ''));

if ($conversationId <= 0) api_error('conversation_id is required.', 400, 'MISSING_FIELD');
if ($raterId  <= 0)       api_error('rater_id is required.',        400, 'MISSING_FIELD');
if ($targetId <= 0)       api_error('target_id is required.',       400, 'MISSING_FIELD');
if ($raterId === $targetId) api_error('Cannot rate yourself.',      400, 'SELF_RATE');
if ($stars < 1 || $stars > 5) api_error('stars must be between 1 and 5.', 400, 'INVALID_STARS');

// Verify rater belongs to this conversation
$check = $conn->prepare(
    'SELECT id FROM conversations
     WHERE id = ? AND (user1_id = ? OR user2_id = ?) LIMIT 1'
);
if (!$check) api_error('Server error.', 500);
$check->bind_param('iii', $conversationId, $raterId, $raterId);
$check->execute();
if (!$check->get_result()->fetch_assoc()) {
    $check->close();
    api_error('Conversation not found or access denied.', 404, 'NOT_FOUND');
}
$check->close();

// Prevent duplicate ratings for the same conversation pair
$dup = $conn->prepare(
    'SELECT id FROM ratings
     WHERE conversation_id = ? AND rater_id = ? AND target_id = ? LIMIT 1'
);
if (!$dup) api_error('Server error.', 500);
$dup->bind_param('iii', $conversationId, $raterId, $targetId);
$dup->execute();
if ($dup->get_result()->fetch_assoc()) {
    $dup->close();
    api_error('You have already rated this user for this interaction.', 409, 'ALREADY_RATED');
}
$dup->close();

// Insert rating
$ins = $conn->prepare(
    'INSERT INTO ratings (conversation_id, rater_id, target_id, stars, comment, created_at)
     VALUES (?, ?, ?, ?, ?, NOW())'
);
if (!$ins) api_error('Server error preparing insert.', 500);

$ins->bind_param('iiiis', $conversationId, $raterId, $targetId, $stars, $comment);
if (!$ins->execute()) {
    error_log('submit_rating insert error: ' . $ins->error);
    $ins->close();
    api_error('Could not save rating. Please try again.', 500);
}
$newId = (int)$ins->insert_id;
$ins->close();

api_success(['rating_id' => $newId]);
