<?php
/**
 * api_get_lostfound_rated.php  →  upload as: get_lostfound_rated.php
 *
 * Returns all active lost & found items with avg_rating + rating_count
 * for each poster, pulled directly from the database.
 */

declare(strict_types=1);

require_once __DIR__ . '/api_helpers.php';

$type     = trim(strtolower((string)($_GET['type']     ?? '')));
$category = trim((string)($_GET['category'] ?? ''));

// Build WHERE clause
$where  = "l.status IN ('active','open')";
$params = [];
$types  = '';

if ($type !== '' && $type !== 'all') {
    $where   .= ' AND l.type = ?';
    $params[] = $type;
    $types   .= 's';
}

if ($category !== '' && strtolower($category) !== 'all') {
    $where   .= ' AND l.category = ?';
    $params[] = $category;
    $types   .= 's';
}

$sql = "
    SELECT
        l.id,
        l.title,
        l.description,
        l.category,
        l.type,
        l.status,
        l.location,
        l.image_url          AS image,
        l.created_at,
        l.poster_id          AS poster_id,
        u.username           AS poster,
        u.email              AS posterEmail,
        ROUND(AVG(r.stars), 1) AS avg_rating,
        COUNT(r.id)            AS rating_count
    FROM lost_found_items l
    JOIN  users u  ON u.id = l.poster_id
    LEFT JOIN ratings r ON r.target_id = l.poster_id
    WHERE $where
    GROUP BY l.id
    ORDER BY l.created_at DESC
";

$stmt = $conn->prepare($sql);
if (!$stmt) api_error('Server error: ' . $conn->error, 500);

if ($types !== '') {
    $stmt->bind_param($types, ...$params);
}

$stmt->execute();
$res  = $stmt->get_result();
$rows = [];
while ($row = $res->fetch_assoc()) {
    $row['avg_rating']   = $row['avg_rating']   !== null ? (float)$row['avg_rating']   : null;
    $row['rating_count'] = (int)($row['rating_count'] ?? 0);
    $rows[] = $row;
}
$stmt->close();

api_success($rows);
