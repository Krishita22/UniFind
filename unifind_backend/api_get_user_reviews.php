<?php
/**
 * api_get_user_reviews.php  →  upload as: get_user_reviews.php
 *
 * Returns all reviews for a user in full detail.
 *
 * GET get_user_reviews.php?user_id=123
 */
declare(strict_types=1);
require_once __DIR__ . '/api_helpers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') api_error('Method not allowed.', 405);

$userId = (int)($_GET['user_id'] ?? 0);
if ($userId <= 0) api_error('user_id is required.', 400);

$stmt = $conn->prepare(
    'SELECT r.id, r.stars, r.comment, r.created_at,
            u.username AS rater_username,
            u.display_name AS rater_name
     FROM ratings r
     JOIN users u ON u.id = r.rater_id
     WHERE r.target_id = ?
     ORDER BY r.created_at DESC'
);
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('i', $userId);
$stmt->execute();
$rows = [];
$res = $stmt->get_result();
while ($row = $res->fetch_assoc()) $rows[] = $row;
$stmt->close();

api_success($rows);
