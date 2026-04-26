<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$claimId = (int)($body['claim_id'] ?? 0);

if ($claimId <= 0) api_error('claim_id required.', 400);

// Get claim details
$claimStmt = $conn->prepare("
    SELECT c.id, c.claimant_id, c.found_item_id, c.status,
           u.email as claimant_email, u.username as claimant_username,
           lf.title as item_title
    FROM lost_found_claims c
    JOIN users u ON c.claimant_id = u.id
    JOIN lost_found_items lf ON c.found_item_id = lf.id
    WHERE c.id = ? LIMIT 1
");
if (!$claimStmt) api_error('Prepare error: ' . $conn->error, 500);
$claimStmt->bind_param('i', $claimId);
if (!$claimStmt->execute()) api_error('Execute error: ' . $claimStmt->error, 500);
$claim = $claimStmt->get_result()->fetch_assoc();
$claimStmt->close();

if (!$claim) api_error('Claim not found.', 404);

// Record approval in claim_approvals
$approvalStmt = $conn->prepare("
    INSERT INTO claim_approvals (claim_id, status, approved_at)
    VALUES (?, 'approved', NOW())
");
if (!$approvalStmt) api_error('Approval insert prepare: ' . $conn->error, 500);
$approvalStmt->bind_param('i', $claimId);
if (!$approvalStmt->execute()) api_error('Approval insert execute: ' . $approvalStmt->error, 500);
$approvalStmt->close();

// Update claim status
$updateStmt = $conn->prepare("UPDATE lost_found_claims SET status = 'approved' WHERE id = ?");
if (!$updateStmt) api_error('Update prepare: ' . $conn->error, 500);
$updateStmt->bind_param('i', $claimId);
if (!$updateStmt->execute()) api_error('Update execute: ' . $updateStmt->error, 500);
$updateStmt->close();

// Send email to claimant
$subject = 'Your Claim Has Been Approved';
$body = "Hi {$claim['claimant_username']},\n\nYour claim for the item '{$claim['item_title']}' has been approved!\n\nYou can now propose a meetup time and location with the item finder.\n\nBest regards,\nUniFind Team";
$headers = "From: UniFind <unifind@ivanovs1.nodomain>\r\n";
@mail($claim['claimant_email'], $subject, $body, $headers);

api_success([
    'claim_id' => $claimId,
    'status' => 'approved'
]);
?>
