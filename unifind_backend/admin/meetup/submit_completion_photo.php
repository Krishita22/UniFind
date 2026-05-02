<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$body     = json_decode(file_get_contents('php://input'), true) ?? [];
$meetupId = (int)($body['meetup_id'] ?? 0);
$userId   = (int)($body['user_id']   ?? 0);
$photoUrl = trim($body['photo_url']  ?? '');

if (!$meetupId || !$userId || !$photoUrl) api_error('Missing required fields.');

// ── Try marketplace meetups first ─────────────────────────────────────────
$stmt = $conn->prepare("SELECT buyer_id, seller_id, status, buyer_photo_url, seller_photo_url, item_id FROM meetups WHERE meetup_id = ? LIMIT 1");
if (!$stmt) api_error('Server error.', 500);
$stmt->bind_param('i', $meetupId);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if ($row) {
    // Marketplace meetup
    if ($row['status'] !== 'confirmed') api_error('Meetup is not in confirmed state.');
    $isBuyer  = (int)$row['buyer_id']  === $userId;
    $isSeller = (int)$row['seller_id'] === $userId;
    if (!$isBuyer && !$isSeller) api_error('User is not part of this meetup.', 403);

    $col = $isBuyer ? 'buyer_photo_url' : 'seller_photo_url';
    $upd = $conn->prepare("UPDATE meetups SET $col = ? WHERE meetup_id = ?");
    $upd->bind_param('si', $photoUrl, $meetupId);
    $upd->execute();
    $upd->close();

    $chk = $conn->prepare("SELECT buyer_photo_url, seller_photo_url, item_id FROM meetups WHERE meetup_id = ? LIMIT 1");
    $chk->bind_param('i', $meetupId);
    $chk->execute();
    $updated = $chk->get_result()->fetch_assoc();
    $chk->close();

    $bothSubmitted = !empty($updated['buyer_photo_url']) && !empty($updated['seller_photo_url']);
    if ($bothSubmitted) {
        $mv = $conn->prepare("UPDATE meetups SET status = 'completion_pending' WHERE meetup_id = ?");
        $mv->bind_param('i', $meetupId);
        $mv->execute();
        $mv->close();
    }

    api_success([
        'meetup_id'      => $meetupId,
        'both_submitted' => $bothSubmitted,
        'status'         => $bothSubmitted ? 'completion_pending' : 'confirmed',
        'is_marketplace' => true,
    ]);
}

// ── Try lost & found meetups ──────────────────────────────────────────────
$stmt2 = $conn->prepare("
    SELECT m.id, m.status, m.buyer_photo_url, m.seller_photo_url,
           lm.lost_item_id, lm.matched_found_item_id,
           li.poster_id AS lost_poster_id, fi.poster_id AS found_poster_id
    FROM lost_found_meetups m
    JOIN lost_found_matches lm ON m.match_id = lm.id
    LEFT JOIN lost_found_items li ON lm.lost_item_id = li.id
    LEFT JOIN lost_found_items fi ON lm.matched_found_item_id = fi.id
    WHERE m.id = ? LIMIT 1
");
if (!$stmt2) api_error('Server error.', 500);
$stmt2->bind_param('i', $meetupId);
$stmt2->execute();
$row2 = $stmt2->get_result()->fetch_assoc();
$stmt2->close();

if (!$row2) api_error('Meetup not found.', 404);
if ($row2['status'] !== 'confirmed') api_error('Meetup is not in confirmed state.');

$isLostPoster  = (int)$row2['lost_poster_id']  === $userId;
$isFoundPoster = (int)$row2['found_poster_id'] === $userId;
if (!$isLostPoster && !$isFoundPoster) api_error('User is not part of this meetup.', 403);

$col2 = $isLostPoster ? 'buyer_photo_url' : 'seller_photo_url';
$upd2 = $conn->prepare("UPDATE lost_found_meetups SET $col2 = ? WHERE id = ?");
$upd2->bind_param('si', $photoUrl, $meetupId);
$upd2->execute();
$upd2->close();

$chk2 = $conn->prepare("SELECT buyer_photo_url, seller_photo_url FROM lost_found_meetups WHERE id = ? LIMIT 1");
$chk2->bind_param('i', $meetupId);
$chk2->execute();
$updated2 = $chk2->get_result()->fetch_assoc();
$chk2->close();

$bothSubmitted2 = !empty($updated2['buyer_photo_url']) && !empty($updated2['seller_photo_url']);
if ($bothSubmitted2) {
    $mv2 = $conn->prepare("UPDATE lost_found_meetups SET status = 'completion_pending' WHERE id = ?");
    $mv2->bind_param('i', $meetupId);
    $mv2->execute();
    $mv2->close();
}

api_success([
    'meetup_id'      => $meetupId,
    'both_submitted' => $bothSubmitted2,
    'status'         => $bothSubmitted2 ? 'completion_pending' : 'confirmed',
    'is_marketplace' => false,
]);
?>