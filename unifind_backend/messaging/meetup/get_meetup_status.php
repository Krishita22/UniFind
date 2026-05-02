<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$idsStr = $_GET['ids'] ?? '';
if (empty($idsStr)) api_error('ids parameter required.', 400);

$ids = array_map('intval', array_filter(explode(',', $idsStr), 'is_numeric'));
if (empty($ids)) api_error('No valid ids provided.', 400);

$result = [];

// Query marketplace meetups
$placeholders = implode(',', array_fill(0, count($ids), '?'));
$stmt = $conn->prepare("
    SELECT
        meetup_id,
        status,
        buyer_id,
        seller_id,
        buyer_photo_url,
        seller_photo_url
    FROM meetups
    WHERE meetup_id IN ($placeholders)
");

if ($stmt) {
    $stmt->bind_param(str_repeat('i', count($ids)), ...$ids);
    $stmt->execute();
    $rows = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

    foreach ($rows as $row) {
        $result[(string)$row['meetup_id']] = [
            'status' => $row['status'],
            'buyer_id' => (int)$row['buyer_id'],
            'seller_id' => (int)$row['seller_id'],
            'buyer_photo_url' => $row['buyer_photo_url'],
            'seller_photo_url' => $row['seller_photo_url'],
            'type' => 'marketplace',
        ];
    }
}

// Query lost & found meetups
$stmt = $conn->prepare("
    SELECT id, status
    FROM lost_found_meetups
    WHERE id IN ($placeholders)
");

if ($stmt) {
    $stmt->bind_param(str_repeat('i', count($ids)), ...$ids);
    $stmt->execute();
    $rows = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

    foreach ($rows as $row) {
        $statusMap = [
            'user_pending' => 'user_pending',
            'admin_pending' => 'admin_pending',
            'confirmed' => 'confirmed',
            'user_denied' => 'user_cancelled',
            'completed' => 'completed',
        ];
        $mappedStatus = isset($statusMap[$row['status']]) ? $statusMap[$row['status']] : $row['status'];

        $result[(string)$row['id']] = [
            'status' => $mappedStatus,
            'type' => 'lost_found',
        ];
    }
}

api_success($result);
?>
