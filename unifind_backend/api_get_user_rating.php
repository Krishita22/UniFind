<?php
/**
 * api_get_user_rating.php  →  upload as: get_user_rating.php
 *
 * Returns the average star rating and total count for a given user.
 * Used to display ratings on listing cards and detail screens.
 *
 * GET get_user_rating.php?user_id=123
 *
 * Response:
 *   { "success": true, "avg": 4.3, "count": 12 }
 */

declare(strict_types=1);

require_once __DIR__ . '/api_helpers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    api_error('Method not allowed.', 405);
}

$userId = (int)($_GET['user_id'] ?? 0);
if ($userId <= 0) {
    api_error('user_id is required.', 400, 'MISSING_FIELD');
}

$stmt = $conn->prepare(
    'SELECT
         ROUND(AVG(stars), 1) AS avg_stars,
         COUNT(*)             AS total
     FROM ratings
     WHERE target_id = ?'
);
if (!$stmt) api_error('Server error.', 500);

$stmt->bind_param('i', $userId);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

$avg   = $row['avg_stars'] !== null ? (float)$row['avg_stars'] : 0.0;
$count = (int)($row['total'] ?? 0);

api_success(['avg' => $avg, 'count' => $count]);
