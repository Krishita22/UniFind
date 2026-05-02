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

$body    = api_body();
$matchId = (int)($body['match_id'] ?? 0);
if ($matchId <= 0) api_error('match_id required.', 400);

// Get the match
$mStmt = $conn->prepare('SELECT id, lost_item_id, matched_found_item_id FROM lost_found_matches WHERE id = ? LIMIT 1');
if (!$mStmt) api_error('Server error.', 500);
$mStmt->bind_param('i', $matchId);
$mStmt->execute();
$match = $mStmt->get_result()->fetch_assoc();
$mStmt->close();
if (!$match) api_error('Match not found.', 404);

// Update match status to unmatched
$upd = $conn->prepare('UPDATE lost_found_matches SET status = "rejected" WHERE id = ?');
if (!$upd) api_error('Server error.', 500);
$upd->bind_param('i', $matchId);
if (!$upd->execute()) api_error('Failed to unmatch.', 500);
$upd->close();

// Return both items to active status
$lostId  = (int)$match['lost_item_id'];
$foundId = (int)$match['matched_found_item_id'];
$res = $conn->prepare('UPDATE lost_found_items SET status = "active" WHERE id IN (?, ?)');
if ($res) {
    $res->bind_param('ii', $lostId, $foundId);
    $res->execute();
    $res->close();
}

api_success(['match_id' => $matchId, 'status' => 'unmatched']);
