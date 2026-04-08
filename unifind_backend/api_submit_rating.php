<?php
// upload as: submit_rating.php
declare(strict_types=1);
require_once __DIR__ . '/api_helpers.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body    = api_body();
$convId  = (int)($body['conversation_id'] ?? 0);
$raterId = (int)($body['rater_id'] ?? 0);
$targId  = (int)($body['target_id'] ?? 0);
$stars   = (int)($body['stars'] ?? 0);
$comment = trim((string)($body['comment'] ?? ''));

if ($convId <= 0 || $raterId <= 0 || $targId <= 0) api_error('Missing fields.', 400);
if ($stars < 1 || $stars > 5) api_error('Stars must be 1-5.', 400);
if ($raterId === $targId) api_error('Cannot rate yourself.', 400);

$ins = $conn->prepare('INSERT INTO ratings (conversation_id, rater_id, target_id, stars, comment, created_at) VALUES (?, ?, ?, ?, ?, NOW())');
if (!$ins) api_error('Server error.', 500);
$ins->bind_param('iiiis', $convId, $raterId, $targId, $stars, $comment);
if (!$ins->execute()) { api_error('Already rated or server error.', 409); }
$id = (int)$ins->insert_id;
$ins->close();
api_success(['rating_id' => $id]);
