<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../crypto.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$userId = (int)($_GET['user_id'] ?? 0);
if ($userId <= 0) api_error('user_id required.', 400);

$stmt = $conn->prepare(
    'SELECT c.id, c.subject, c.listing_id, c.user1_id, c.user2_id,
            u1.username AS user1_name, u2.username AS user2_name,
            u1.email AS user1_email, u2.email AS user2_email,
            u1.first_name AS user1_first_name, u2.first_name AS user2_first_name,
            (SELECT m.body FROM messages m WHERE m.conversation_id = c.id ORDER BY m.sent_at DESC LIMIT 1) AS last_msg,
            (SELECT m.sent_at FROM messages m WHERE m.conversation_id = c.id ORDER BY m.sent_at DESC LIMIT 1) AS last_at,
            (SELECT COUNT(*) FROM messages m WHERE m.conversation_id = c.id AND m.sender_id != ? AND m.is_read = 0) AS unread,
            c.is_complete,
            CASE
                WHEN c.listing_id IS NULL THEN 1
                WHEN lfi.id IS NOT NULL THEN 1
                WHEN lfc.id IS NOT NULL THEN 1
                WHEN lfm.id IS NOT NULL THEN 1
                WHEN mt.id IS NOT NULL THEN 1
                WHEN c.subject LIKE "Match:%" THEN 1
                WHEN c.subject LIKE "Claim Approved:%" THEN 1
                WHEN c.subject LIKE "Lost & Found:%" THEN 1
                ELSE 0
            END AS is_lost_found
     FROM conversations c
     JOIN users u1 ON u1.id = c.user1_id
     JOIN users u2 ON u2.id = c.user2_id
     LEFT JOIN lost_found_items lfi ON lfi.id = c.listing_id
     LEFT JOIN lost_found_claims lfc ON lfc.id = c.listing_id
     LEFT JOIN lost_found_matches lfm ON lfm.id = c.listing_id
     LEFT JOIN matches mt ON mt.id = c.listing_id
     WHERE c.user1_id = ? OR c.user2_id = ?
     ORDER BY last_at DESC'
);
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('iii', $userId, $userId, $userId);
$stmt->execute();
$rows = [];
$res  = $stmt->get_result();
while ($row = $res->fetch_assoc()) {
    $row['last_msg'] = decrypt_message_body($row['last_msg'] ?? null);
    $rows[] = $row;
}
$stmt->close();
api_success($rows);
?>
