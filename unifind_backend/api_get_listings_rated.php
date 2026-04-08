<?php
/**
 * api_get_listings_rated.php  →  upload as: get_listings_rated.php
 *
 * Returns all active marketplace listings with avg_rating + rating_count
 * for each seller, pulled directly from the database.
 */

declare(strict_types=1);

require_once __DIR__ . '/api_helpers.php';

$category = trim((string)($_GET['category'] ?? ''));

// Build WHERE clause
$where  = "m.status IN ('active','approved')";
$params = [];
$types  = '';

if ($category !== '' && strtolower($category) !== 'all') {
    $where   .= ' AND m.category = ?';
    $params[] = $category;
    $types   .= 's';
}

$sql = "
    SELECT
        m.id,
        m.title,
        m.description,
        m.price,
        m.category,
        m.condition,
        m.location,
        m.image_url          AS image,
        m.created_at,
        m.seller_id          AS seller_id,
        u.username           AS seller,
        u.email              AS sellerEmail,
        ROUND(AVG(r.stars), 1) AS avg_rating,
        COUNT(r.id)            AS rating_count
    FROM marketplace_items m
    JOIN  users u  ON u.id = m.seller_id
    LEFT JOIN ratings r ON r.target_id = m.seller_id
    WHERE $where
    GROUP BY m.id
    ORDER BY m.created_at DESC
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
    // Normalise nulls so Flutter doesn't have to handle missing keys
    $row['avg_rating']   = $row['avg_rating']   !== null ? (float)$row['avg_rating']   : null;
    $row['rating_count'] = (int)($row['rating_count'] ?? 0);
    $rows[] = $row;
}
$stmt->close();

api_success($rows);
