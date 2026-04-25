<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) {
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
    function api_body(): array {
        $raw = file_get_contents('php://input');
        if ($raw === false || $raw === '') return [];
        $decoded = json_decode($raw, true);
        return is_array($decoded) ? $decoded : [];
    }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body   = api_body();
$itemId = (int)($body['item_id'] ?? 0);
if ($itemId <= 0) api_error('item_id required.', 400);

// Verify item exists
$iStmt = $conn->prepare('SELECT id FROM lost_found_items WHERE id = ? LIMIT 1');
if (!$iStmt) api_error('Server error.', 500);
$iStmt->bind_param('i', $itemId);
$iStmt->execute();
$item = $iStmt->get_result()->fetch_assoc();
$iStmt->close();
if (!$item) api_error('Item not found.', 404);

// Mark as resolved
$status = 'resolved';
$upd = $conn->prepare('UPDATE lost_found_items SET status = ? WHERE id = ?');
if (!$upd) api_error('Server error.', 500);
$upd->bind_param('si', $status, $itemId);
if (!$upd->execute()) api_error('Failed to resolve item.', 500);
$upd->close();

api_success(['item_id' => $itemId, 'status' => 'resolved']);
