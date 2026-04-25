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

$status = trim($_GET['status'] ?? 'admin_pending');
$allowed = ['user_pending','admin_pending','confirmed','admin_denied','user_denied','completed','user_cancelled','completion_pending','pending','approved','denied','resolved'];
if (!in_array($status, $allowed, true)) api_error('Invalid status.');

$rows = [];

// Map lost & found statuses to marketplace statuses for unified filtering
$lfStatusMap = [
    'pending' => 'user_pending',
    'approved' => 'admin_pending',
    'denied' => 'admin_denied',
    'resolved' => 'completed'
];
$lfStatus = array_search($status, $lfStatusMap) ?: $status;

// Get marketplace meetups
$stmt = $conn->prepare("
    SELECT
        m.meetup_id, m.item_id, m.buyer_id, m.seller_id,
        m.meetup_date, m.meetup_time, m.location, m.status, m.created_at,
        m.buyer_photo_url, m.seller_photo_url,
        b.username AS buyer_username, b.email AS buyer_email,
        s.username AS seller_username, s.email AS seller_email,
        COALESCE(mi.title, lfi.title, 'Meetup') AS item_title,
        mi.price AS item_price,
        mi.category AS item_category,
        mi.image_url AS item_image,
        CASE WHEN mi.id IS NOT NULL THEN 1 ELSE 0 END AS is_marketplace,
        'marketplace' AS meetup_type
    FROM meetups m
    LEFT JOIN users b ON b.id = m.buyer_id
    LEFT JOIN users s ON s.id = m.seller_id
    LEFT JOIN marketplace_items mi ON m.item_id IS NOT NULL AND mi.id = m.item_id
    LEFT JOIN lost_found_items lfi ON m.item_id IS NOT NULL AND lfi.id = m.item_id
    WHERE m.status = ?
    ORDER BY m.created_at DESC
");
if (!$stmt) api_error('Server error: ' . $conn->error, 500);
$stmt->bind_param('s', $status);
$stmt->execute();
$rows = array_merge($rows, $stmt->get_result()->fetch_all(MYSQLI_ASSOC));
$stmt->close();

// Get lost & found meetups if status maps to one
if (in_array($lfStatus, ['pending', 'approved', 'denied', 'resolved'])) {
    $stmt = $conn->prepare("
        SELECT
            m.id AS meetup_id, m.match_id AS item_id, NULL AS buyer_id, NULL AS seller_id,
            m.meetup_date, m.meetup_time, m.meetup_location AS location, m.status, m.created_at,
            NULL AS buyer_photo_url, NULL AS seller_photo_url,
            u_lost.username AS buyer_username, u_lost.email AS buyer_email,
            u_found.username AS seller_username, u_found.email AS seller_email,
            CONCAT(li.title, ' <-> ', fi.title) AS item_title,
            NULL AS item_price,
            NULL AS item_category,
            NULL AS item_image,
            0 AS is_marketplace,
            'lost_found' AS meetup_type
        FROM lost_found_meetups m
        JOIN lost_found_matches lm ON m.match_id = lm.id
        LEFT JOIN lost_found_items li ON lm.lost_item_id = li.id
        LEFT JOIN lost_found_items fi ON lm.matched_found_item_id = fi.id
        LEFT JOIN users u_lost ON li.poster_id = u_lost.id
        LEFT JOIN users u_found ON fi.poster_id = u_found.id
        WHERE m.status = ?
        ORDER BY m.created_at DESC
    ");
    if ($stmt) {
        $stmt->bind_param('s', $lfStatus);
        $stmt->execute();
        $rows = array_merge($rows, $stmt->get_result()->fetch_all(MYSQLI_ASSOC));
        $stmt->close();
    }
}

// Sort combined results by created_at descending
usort($rows, function($a, $b) {
    return strtotime($b['created_at']) - strtotime($a['created_at']);
});

api_success($rows);
