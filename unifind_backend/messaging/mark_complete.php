<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';
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
