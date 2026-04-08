<?php
// upload as: send_message.php
declare(strict_types=1);
require_once __DIR__ . '/api_helpers.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body   = api_body();
$convId = (int)($body['conversation_id'] ?? 0);
$sender = (int)($body['sender_id'] ?? 0);
$text   = trim((string)($body['body'] ?? ''));

if ($convId <= 0 || $sender <= 0 || $text === '') api_error('Missing fields.', 400);

$stmt = $conn->prepare('INSERT INTO messages (conversation_id, sender_id, body, is_read, sent_at) VALUES (?, ?, ?, 0, NOW())');
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('iis', $convId, $sender, $text);
if (!$stmt->execute()) api_error('Failed to send.', 500);
$id = (int)$stmt->insert_id;
$stmt->close();
api_success(['message_id' => $id]);
