<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
    function api_body(): array { $raw = file_get_contents('php://input'); if ($raw === false || $raw === '') return []; $decoded = json_decode($raw, true); return is_array($decoded) ? $decoded : []; }
}

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
