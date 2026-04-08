<?php
declare(strict_types=1);
require_once __DIR__ . '/../api_helpers.php';
if ($_SERVER['REQUEST_METHOD'] !== 'GET') api_error('Method not allowed.', 405);

// Get all lost & found items with their claims and matches
$sql = "SELECT lf.id, lf.title, lf.description, lf.category, lf.type, lf.status,
               lf.image_url AS image, lf.location, lf.created_at,
               u.email AS poster_email, COALESCE(u.username, u.full_name) AS poster_username
        FROM lost_found_items lf
        LEFT JOIN users u ON lf.user_id = u.id
        WHERE lf.status IN ('active','open','pending')
        ORDER BY lf.created_at DESC";
$result = $conn->query($sql);
if (!$result) api_error('Failed to query items.', 500);

$items = [];
while ($row = $result->fetch_assoc()) {
    $itemId = (int)$row['id'];

    // Get claims for this item
    $cStmt = $conn->prepare(
        "SELECT c.id, c.proof_details, c.status, c.created_at,
                u.email AS claimant_email
         FROM lost_found_claims c
         LEFT JOIN users u ON c.claimant_id = u.id
         WHERE c.found_item_id = ?
         ORDER BY c.created_at DESC"
    );
    $claims = [];
    if ($cStmt) {
        $cStmt->bind_param('i', $itemId);
        $cStmt->execute();
        $cRes = $cStmt->get_result();
        while ($c = $cRes->fetch_assoc()) {
            $claims[] = $c;
        }
        $cStmt->close();
    }

    // Get user-submitted matches for this item
    $mStmt = $conn->prepare(
        "SELECT m.id, m.match_details, m.found_location, m.status, m.created_at,
                u.email AS submitter_email
         FROM lost_found_matches m
         LEFT JOIN users u ON m.submitter_id = u.id
         WHERE m.lost_item_id = ? AND m.found_item_id IS NULL
         ORDER BY m.created_at DESC"
    );
    $matches = [];
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
