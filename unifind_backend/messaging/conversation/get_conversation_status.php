<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

require_once __DIR__ . '/../../config.php';

$conversation_id = $_GET['conversation_id'] ?? null;
if (!$conversation_id) {
    echo json_encode(["success" => false, "error" => "Missing conversation_id"]);
    exit;
}

// Check which column name the table actually uses (is_completed vs is_complete)
$col_check = $conn->query("SHOW COLUMNS FROM conversations LIKE 'is_complete%'");
$col_name  = null;
while ($col = $col_check->fetch_assoc()) {
    $col_name = $col['Field'];
}

if (!$col_name) {
    echo json_encode([
        "success" => true,
        "data"    => ["is_complete" => false, "is_completed" => false]
    ]);
    exit;
}

$stmt = $conn->prepare("SELECT `$col_name` AS status_flag FROM conversations WHERE id = ?");
$stmt->bind_param("i", $conversation_id);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$row) {
    echo json_encode([
        "success" => true,
        "data"    => ["is_complete" => false, "is_completed" => false]
    ]);
    exit;
}

$flag = (bool) $row['status_flag'];
echo json_encode([
    "success" => true,
    "data"    => ["is_complete" => $flag, "is_completed" => $flag]
]);