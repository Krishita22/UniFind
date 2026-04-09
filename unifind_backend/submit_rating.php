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
