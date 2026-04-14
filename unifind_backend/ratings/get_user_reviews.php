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
}
if ($_SERVER['REQUEST_METHOD'] !== 'GET') api_error('Method not allowed.', 405);

$userId = (int)($_GET['user_id'] ?? 0);
if ($userId <= 0) api_error('user_id is required.', 400);

$stmt = $conn->prepare(
    'SELECT r.id, r.stars, r.comment, r.created_at,
            u.username AS rater_username,
            u.display_name AS rater_name
     FROM ratings r
     JOIN users u ON u.id = r.rater_id
     WHERE r.target_id = ?
     ORDER BY r.created_at DESC'
);
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('i', $userId);
$stmt->execute();
$rows = [];
$res = $stmt->get_result();
while ($row = $res->fetch_assoc()) $rows[] = $row;
$stmt->close();
api_success($rows);
