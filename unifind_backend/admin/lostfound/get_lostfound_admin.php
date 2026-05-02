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

// Get all lost & found items
$sql = "SELECT lf.id, lf.title, lf.description, lf.category, lf.type, lf.status,
               lf.image_url AS image, lf.location, lf.created_at,
               u.email AS poster_email, u.username AS poster_username
        FROM lost_found_items lf
        LEFT JOIN users u ON lf.poster_id = u.id
        WHERE lf.status IN ('active','open','pending')
        ORDER BY lf.created_at DESC";
$result = $conn->query($sql);
if (!$result) api_error('Items query failed: ' . $conn->error, 500);

$items = [];
while ($row = $result->fetch_assoc()) {
    $itemId = (int)$row['id'];

    // Get claims (table may not exist yet)
    $claims = [];
    $cStmt = @$conn->prepare(
        "SELECT c.id, c.proof_details, c.status, c.created_at,
                u.email AS claimant_email
         FROM lost_found_claims c
         LEFT JOIN users u ON c.claimant_id = u.id
         WHERE c.found_item_id = ?
         ORDER BY c.created_at DESC"
    );
    if ($cStmt) {
        $cStmt->bind_param('i', $itemId);
        $cStmt->execute();
        $cRes = $cStmt->get_result();
        while ($c = $cRes->fetch_assoc()) {
            $claims[] = $c;
        }
        $cStmt->close();
    }

    // Get user-submitted matches (table may not exist yet)
    $matches = [];
    $mStmt = @$conn->prepare(
        "SELECT m.id, m.match_details, m.found_location, m.status, m.created_at,
                u.email AS submitter_email
         FROM lost_found_matches m
         LEFT JOIN users u ON m.submitted_by = u.id
         WHERE m.lost_item_id = ? AND m.matched_found_item_id IS NULL
         ORDER BY m.created_at DESC"
    );
    if ($mStmt) {
        $mStmt->bind_param('i', $itemId);
        $mStmt->execute();
        $mRes = $mStmt->get_result();
        while ($m = $mRes->fetch_assoc()) {
            $matches[] = $m;
        }
        $mStmt->close();
    }

    $row['claims'] = $claims;
    $row['matches'] = $matches;
    $items[] = $row;
}

api_success($items);
