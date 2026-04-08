<?php
// upload as: get_user_rating.php
declare(strict_types=1);
require_once __DIR__ . '/api_helpers.php';

$userId = (int)($_GET['user_id'] ?? 0);
if ($userId <= 0) api_error('user_id required.', 400);

$stmt = $conn->prepare('SELECT ROUND(AVG(stars),1) AS avg_stars, COUNT(*) AS total FROM ratings WHERE target_id = ?');
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('i', $userId);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
api_success(['avg' => $row['avg_stars'] !== null ? (float)$row['avg_stars'] : 0.0, 'count' => (int)($row['total'] ?? 0)]);
