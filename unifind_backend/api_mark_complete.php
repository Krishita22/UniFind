<?php
/**
 * api_mark_complete.php  →  upload as: mark_complete.php
 *
 * Marks a conversation as complete (item handed over / returned).
 * Either participant can call this. Once one side marks it complete,
 * the conversation status updates and both sides can submit ratings.
 *
 * POST mark_complete.php
 * Body (JSON):
 *   { "conversation_id": 1, "user_id": 123 }
 */

declare(strict_types=1);

require_once __DIR__ . '/api_helpers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error('Method not allowed.', 405);
}

$body           = api_body();
$conversationId = (int)($body['conversation_id'] ?? 0);
$userId         = (int)($body['user_id']         ?? 0);

if ($conversationId <= 0) api_error('conversation_id is required.', 400, 'MISSING_FIELD');
if ($userId         <= 0) api_error('user_id is required.',         400, 'MISSING_FIELD');

// Verify user belongs to this conversation
$check = $conn->prepare(
    'SELECT id, is_complete FROM conversations
     WHERE id = ? AND (user1_id = ? OR user2_id = ?) LIMIT 1'
);
if (!$check) api_error('Server error.', 500);
$check->bind_param('iii', $conversationId, $userId, $userId);
$check->execute();
$conv = $check->get_result()->fetch_assoc();
$check->close();

if (!$conv) api_error('Conversation not found or access denied.', 404, 'NOT_FOUND');
if ((int)($conv['is_complete'] ?? 0) === 1) {
    // Already marked — return success so the app can still show the rating dialog
    api_success(['already_complete' => true]);
}

// Mark conversation as complete
$upd = $conn->prepare(
    'UPDATE conversations SET is_complete = 1, completed_at = NOW() WHERE id = ?'
);
if (!$upd) api_error('Server error.', 500);
$upd->bind_param('i', $conversationId);
if (!$upd->execute()) {
    error_log('mark_complete update error: ' . $upd->error);
    $upd->close();
    api_error('Could not mark conversation as complete.', 500);
}
$upd->close();

api_success(['already_complete' => false]);
