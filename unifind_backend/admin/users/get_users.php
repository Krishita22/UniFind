<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit();

require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit();
}

$stmt = $conn->prepare("
    SELECT
        u.id,
        u.email,
        u.username,
        u.display_name,
        u.role,
        u.is_banned,
        u.has_warning,
        u.warned_at,
        u.last_active,
        u.created_at,
        COALESCE(u.is_active, 1) AS is_verified,
        (
            SELECT COUNT(*) FROM marketplace_items m WHERE m.seller_id = u.id
        ) + (
            SELECT COUNT(*) FROM lost_found_items l WHERE l.poster_id = u.id
        ) AS listing_count
    FROM users u
    WHERE u.role != 'admin'
    ORDER BY u.created_at DESC
");
$stmt->execute();
$res = $stmt->get_result();

$users = [];
while ($row = $res->fetch_assoc()) {
    $users[] = [
        'id'           => (int)$row['id'],
        'email'        => $row['email'],
        'username'     => $row['username'],
        'display_name' => $row['display_name'],
        'role'         => $row['role'],
        'is_banned'    => (bool)$row['is_banned'],
        'has_warning'  => (bool)$row['has_warning'],
        'warned_at'    => $row['warned_at'],
        'last_active'  => $row['last_active'],
        'created_at'   => $row['created_at'],
        'is_verified'  => (bool)$row['is_verified'],
        'listing_count'=> (int)$row['listing_count'],
    ];
}
$stmt->close();
$conn->close();

echo json_encode(['success' => true, 'data' => $users]);
?>