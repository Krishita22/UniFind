<?php
// upload as: mark_complete.php
declare(strict_types=1);
require_once __DIR__ . '/api_helpers.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body   = api_body();
$convId = (int)($body['conversation_id'] ?? 0);
$userId = (int)($body['user_id'] ?? 0);
if ($convId <= 0 || $userId <= 0) api_error('Missing fields.', 400);

$chk = $conn->prepare('SELECT id, is_complete FROM conversations WHERE id = ? AND (user1_id = ? OR user2_id = ?) LIMIT 1');
if (!$chk) api_error('Server error.', 500);
$chk->bind_param('iii', $convId, $userId, $userId);
$chk->execute();
$conv = $chk->get_result()->fetch_assoc();
$chk->close();
if (!$conv) api_error('Not found.', 404);
if ((int)($conv['is_complete'] ?? 0) === 1) api_success(['already_complete' => true]);

$upd = $conn->prepare('UPDATE conversations SET is_complete = 1, completed_at = NOW() WHERE id = ?');
if (!$upd) api_error('Server error.', 500);
$upd->bind_param('i', $convId);
$upd->execute();
$upd->close();
api_success(['already_complete' => false]);
