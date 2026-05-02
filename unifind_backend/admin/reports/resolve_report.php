<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit();

require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit();
}

$body     = json_decode(file_get_contents('php://input'), true) ?: [];
$reportId = (int)($body['report_id'] ?? 0);

if ($reportId <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing report_id']);
    exit();
}

$stmt = $conn->prepare("UPDATE reports SET is_resolved = 1 WHERE id = ?");
$stmt->bind_param('i', $reportId);
$ok = $stmt->execute();
$stmt->close();

if ($ok) {
    $desc = "Report #$reportId resolved";
    $alog = $conn->prepare("INSERT INTO admin_activity_log (description, type) VALUES (?, 'report')");
    $alog->bind_param('s', $desc);
    $alog->execute();
    $alog->close();
}

$conn->close();
echo json_encode(['success' => (bool)$ok]);
?>