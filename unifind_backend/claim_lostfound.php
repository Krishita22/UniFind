<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';

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

$body = api_body();
$itemId    = (int)($body['item_id'] ?? 0);
$email     = trim((string)($body['email'] ?? ''));
$proof     = trim((string)($body['proof_details'] ?? ''));
$identify  = trim((string)($body['identifying_details'] ?? ''));
$lastSeen  = trim((string)($body['last_seen_context'] ?? ''));
$contact   = trim((string)($body['contact_note'] ?? ''));

if ($itemId <= 0) api_error('item_id required.', 400);
if ($email === '') api_error('email required.', 400);
if ($proof === '') api_error('proof_details required.', 400);

// Look up user by email
$uStmt = $conn->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
if (!$uStmt) api_error('Server error.', 500);
$uStmt->bind_param('s', $email);
$uStmt->execute();
$uRow = $uStmt->get_result()->fetch_assoc();
$uStmt->close();
if (!$uRow) api_error('User not found.', 404);
$claimantId = (int)$uRow['id'];

// Verify item exists
$iStmt = $conn->prepare('SELECT id FROM lost_found_items WHERE id = ? LIMIT 1');
if (!$iStmt) api_error('Server error.', 500);
$iStmt->bind_param('i', $itemId);
$iStmt->execute();
$iRow = $iStmt->get_result()->fetch_assoc();
$iStmt->close();
if (!$iRow) api_error('Item not found.', 404);

// Insert claim
$ins = $conn->prepare(
    'INSERT INTO lost_found_claims (found_item_id, claimant_id, proof_details, identifying_details, last_seen_context, contact_note, status, created_at)
     VALUES (?, ?, ?, ?, ?, ?, "pending", NOW())'
);
if (!$ins) api_error('Server error.', 500);
$ins->bind_param('iissss', $itemId, $claimantId, $proof, $identify, $lastSeen, $contact);
if (!$ins->execute()) {
    api_error('Failed to submit claim.', 500);
}
$claimId = (int)$ins->insert_id;
$ins->close();

api_success(['claim_id' => $claimId]);
