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

if ($_SERVER['REQUEST_METHOD'] !== 'GET') api_error('Method not allowed.', 405);

// Check if table exists first
$check = @$conn->query("SELECT 1 FROM lost_found_matches LIMIT 1");
if (!$check) {
    api_success([]);
}

$sql = "SELECT m.id AS match_id, m.status, m.created_at,
               m.lost_item_id, m.matched_found_item_id
        FROM lost_found_matches m
        WHERE m.matched_found_item_id IS NOT NULL
        AND m.status != 'rejected'
        ORDER BY m.created_at DESC";
$result = $conn->query($sql);
if (!$result) api_error('Failed to query matches: ' . $conn->error, 500);

$matches = [];
while ($row = $result->fetch_assoc()) {
    $lostId  = (int)$row['lost_item_id'];
    $foundId = (int)$row['matched_found_item_id'];

    $itemSql = "SELECT lf.id, lf.title, lf.description, lf.category, lf.type, lf.status,
                       lf.image_url AS image, lf.location, lf.created_at,
                       u.email AS poster_email, u.username AS poster_username
                FROM lost_found_items lf
                LEFT JOIN users u ON lf.poster_id = u.id
                WHERE lf.id = ? LIMIT 1";

    $lStmt = $conn->prepare($itemSql);
    $lostItem = null;
    if ($lStmt) {
        $lStmt->bind_param('i', $lostId);
        $lStmt->execute();
        $lostItem = $lStmt->get_result()->fetch_assoc();
        $lStmt->close();
    }

    $fStmt = $conn->prepare($itemSql);
    $foundItem = null;
    if ($fStmt) {
        $fStmt->bind_param('i', $foundId);
        $fStmt->execute();
        $foundItem = $fStmt->get_result()->fetch_assoc();
        $fStmt->close();
    }

    $matches[] = [
        'match_id'   => $row['match_id'],
        'status'     => $row['status'],
        'created_at' => $row['created_at'],
        'lost_item'  => $lostItem ?? [],
        'found_item' => $foundItem ?? [],
    ];
}

api_success($matches);
