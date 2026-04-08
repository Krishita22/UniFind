<?php
declare(strict_types=1);
require_once __DIR__ . '/../api_helpers.php';
if ($_SERVER['REQUEST_METHOD'] !== 'GET') api_error('Method not allowed.', 405);

$sql = "SELECT m.id AS match_id, m.status, m.created_at,
               m.lost_item_id, m.found_item_id
        FROM lost_found_matches m
        WHERE m.found_item_id IS NOT NULL
        ORDER BY m.created_at DESC";
$result = $conn->query($sql);
if (!$result) api_error('Failed to query matches.', 500);

$matches = [];
while ($row = $result->fetch_assoc()) {
    $lostId  = (int)$row['lost_item_id'];
    $foundId = (int)$row['found_item_id'];

    // Fetch lost item
    $lStmt = $conn->prepare(
        "SELECT lf.id, lf.title, lf.description, lf.category, lf.type, lf.status,
                lf.image_url AS image, lf.location, lf.created_at,
                u.email AS poster_email, COALESCE(u.username, u.full_name) AS poster_username
         FROM lost_found_items lf
         LEFT JOIN users u ON lf.user_id = u.id
         WHERE lf.id = ? LIMIT 1"
    );
    $lostItem = null;
    if ($lStmt) {
        $lStmt->bind_param('i', $lostId);
        $lStmt->execute();
        $lostItem = $lStmt->get_result()->fetch_assoc();
        $lStmt->close();
    }

    // Fetch found item
    $fStmt = $conn->prepare(
        "SELECT lf.id, lf.title, lf.description, lf.category, lf.type, lf.status,
                lf.image_url AS image, lf.location, lf.created_at,
                u.email AS poster_email, COALESCE(u.username, u.full_name) AS poster_username
         FROM lost_found_items lf
         LEFT JOIN users u ON lf.user_id = u.id
         WHERE lf.id = ? LIMIT 1"
    );
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
