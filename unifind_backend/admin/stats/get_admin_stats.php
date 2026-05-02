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

// Total active listings (marketplace)
$r1 = $conn->query("SELECT COUNT(*) as cnt FROM marketplace_items WHERE is_active = 1 AND status = 'active'");
$totalActive = (int)$r1->fetch_assoc()['cnt'];

// Pending approvals (marketplace + lost_found combined)
$r2 = $conn->query("SELECT COUNT(*) as cnt FROM marketplace_items WHERE status = 'pending'");
$pendingMarket = (int)$r2->fetch_assoc()['cnt'];

$r3 = $conn->query("SELECT COUNT(*) as cnt FROM lost_found_items WHERE status = 'pending'");
$pendingLF = (int)$r3->fetch_assoc()['cnt'];
$pendingTotal = $pendingMarket + $pendingLF;

// New users this week
$r4 = $conn->query("SELECT COUNT(*) as cnt FROM users WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)");
$newUsers = (int)$r4->fetch_assoc()['cnt'];

// Open reports
$r5 = $conn->query("SELECT COUNT(*) as cnt FROM reports WHERE is_resolved = 0");
$openReports = (int)$r5->fetch_assoc()['cnt'];

// Recent activity (last 20 entries from admin_activity_log)
$r6 = $conn->query("SELECT description, type, created_at as timestamp FROM admin_activity_log ORDER BY created_at DESC LIMIT 20");
$activity = [];
while ($row = $r6->fetch_assoc()) {
    $activity[] = $row;
}

echo json_encode([
    'success' => true,
    'data' => [
        'total_active_listings' => $totalActive,
        'pending_approvals'     => $pendingTotal,
        'new_users_this_week'   => $newUsers,
        'open_reports'          => $openReports,
        'recent_activity'       => $activity,
    ]
]);

$conn->close();
?>