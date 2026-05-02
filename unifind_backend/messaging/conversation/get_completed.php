<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data = []) {
        header('Content-Type: application/json');
        echo json_encode(['success' => true, 'data' => $data]);
        exit;
    }
    function api_error(string $message, int $status = 400) {
        http_response_code($status);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'error' => $message]);
        exit;
    }
}

$conversationId = isset($_GET['conversation_id']) ? (int)$_GET['conversation_id'] : 0;
if ($conversationId <= 0) api_error('conversation_id required.');

$stmt = $conn->prepare('SELECT is_complete FROM conversations WHERE id = ?');
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('i', $conversationId);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$row) api_error('Conversation not found.', 404);

api_success(['is_complete' => (int)$row['is_complete']]);