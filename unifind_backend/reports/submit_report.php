<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit();

require_once __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit();
}

$body         = json_decode(file_get_contents('php://input'), true) ?: [];
$targetId     = trim($body['target_id']     ?? '');
$targetType   = trim($body['target_type']   ?? '');
$targetTitle  = trim($body['target_title']  ?? '');
$reporterEmail= trim($body['reporter_email']?? '');
$reason       = trim($body['reason']        ?? '');
$notes        = trim($body['notes']         ?? '');

if ($targetId === '' || $targetType === '' || $reporterEmail === '' || $reason === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields']);
    exit();
}

// Validate target_type
$allowedTypes = ['listing', 'lostfound', 'user'];
if (!in_array($targetType, $allowedTypes)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Invalid target_type']);
    exit();
}

// Check reporter exists
$chk = $conn->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
$chk->bind_param('s', $reporterEmail);
$chk->execute();
$reporter = $chk->get_result()->fetch_assoc();
$chk->close();

if (!$reporter) {
    http_response_code(404);
    echo json_encode(['success' => false, 'error' => 'Reporter not found']);
    exit();
}

// Prevent duplicate open reports from the same user on the same target
$dup = $conn->prepare("
    SELECT id FROM reports
    WHERE reporter_email = ? AND target_id = ? AND is_resolved = 0
    LIMIT 1
");
$dup->bind_param('ss', $reporterEmail, $targetId);
$dup->execute();
$existing = $dup->get_result()->fetch_assoc();
$dup->close();

if ($existing) {
    // Return success silently — don't tell the user it's a duplicate
    // to avoid revealing whether a report exists
    echo json_encode(['success' => true, 'message' => 'Report received']);
    exit();
}

// Insert the report
$stmt = $conn->prepare("
    INSERT INTO reports (reporter_email, target_id, target_type, target_title, reason, notes)
    VALUES (?, ?, ?, ?, ?, ?)
");
$stmt->bind_param('ssssss', $reporterEmail, $targetId, $targetType, $targetTitle, $reason, $notes);
$ok = $stmt->execute();
$stmt->close();

$conn->close();
echo json_encode(['success' => (bool)$ok]);
?>