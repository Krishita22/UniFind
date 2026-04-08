<?php
declare(strict_types=1);
require_once __DIR__ . '/../api_helpers.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body    = api_body();
$matchId = (int)($body['match_id'] ?? 0);
if ($matchId <= 0) api_error('match_id required.', 400);

// Get the match
$mStmt = $conn->prepare('SELECT id, lost_item_id, found_item_id FROM lost_found_matches WHERE id = ? LIMIT 1');
if (!$mStmt) api_error('Server error.', 500);
$mStmt->bind_param('i', $matchId);
$mStmt->execute();
$match = $mStmt->get_result()->fetch_assoc();
$mStmt->close();
if (!$match) api_error('Match not found.', 404);

// Update match status
$upd = $conn->prepare('UPDATE lost_found_matches SET status = "resolved" WHERE id = ?');
if (!$upd) api_error('Server error.', 500);
$upd->bind_param('i', $matchId);
if (!$upd->execute()) api_error('Failed to resolve match.', 500);
$upd->close();

// Mark both items as resolved
$lostId  = (int)$match['lost_item_id'];
$foundId = (int)$match['found_item_id'];
$res = $conn->prepare('UPDATE lost_found_items SET status = "resolved" WHERE id IN (?, ?)');
if ($res) {
    $res->bind_param('ii', $lostId, $foundId);
    $res->execute();
    $res->close();
}

api_success(['match_id' => $matchId, 'status' => 'resolved']);
