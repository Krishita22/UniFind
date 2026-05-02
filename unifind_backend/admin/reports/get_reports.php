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
    SELECT id, reporter_email, target_id, target_type,
           target_title, reason, notes, is_resolved, created_at
    FROM reports
    ORDER BY is_resolved ASC, created_at DESC
");
$stmt->execute();
$res = $stmt->get_result();

$reports = [];
while ($row = $res->fetch_assoc()) {
    $reports[] = [
        'id'             => $row['id'],
        'reporter_email' => $row['reporter_email'],
        'target_id'      => $row['target_id'],
        'target_type'    => $row['target_type'],
        'target_title'   => $row['target_title'],
        'reason'         => $row['reason'],
        'notes'          => $row['notes'],
        'is_resolved'    => (bool)$row['is_resolved'],
        'created_at'     => $row['created_at'],
    ];
}
$stmt->close();
$conn->close();

echo json_encode(['success' => true, 'data' => $reports]);
?>