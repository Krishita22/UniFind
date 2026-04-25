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
if ($meetupId <= 0) api_error('meetup_id required.');

// Try lost & found meetup first
$lfStmt = $conn->prepare("
    SELECT m.*, lm.lost_item_id, lm.matched_found_item_id,
           li.title AS lost_title, li.poster_id AS lost_poster_id,
           fi.title AS found_title, fi.poster_id AS found_poster_id,
           u_lost.email AS lost_email, u_lost.username AS lost_username,
           u_found.email AS found_email, u_found.username AS found_username
    FROM lost_found_meetups m
    JOIN lost_found_matches lm ON m.match_id = lm.id
    LEFT JOIN lost_found_items li ON lm.lost_item_id = li.id
    LEFT JOIN lost_found_items fi ON lm.matched_found_item_id = fi.id
    LEFT JOIN users u_lost ON li.poster_id = u_lost.id
    LEFT JOIN users u_found ON fi.poster_id = u_found.id
    WHERE m.id = ? LIMIT 1
");

$isLostFound = false;
$lfRow = null;

if ($lfStmt) {
    $lfStmt->bind_param('i', $meetupId);
    $lfStmt->execute();
    $lfRow = $lfStmt->get_result()->fetch_assoc();
    $lfStmt->close();
    $isLostFound = $lfRow !== null;
}

if ($isLostFound) {
    // Approve lost & found meetup
    $status = 'approved';
    $upd = $conn->prepare('UPDATE lost_found_meetups SET status = ? WHERE id = ?');
    if (!$upd) api_error('Server error.', 500);
    $upd->bind_param('si', $status, $meetupId);
    if (!$upd->execute()) api_error('Failed to approve: ' . $upd->error, 500);
    $upd->close();

    // Send emails to both users
    $dateFormatted = date('D, M j, Y', strtotime($lfRow['meetup_date']));
    $timeFormatted = date('g:i A', strtotime($lfRow['meetup_time']));
    $location = htmlspecialchars($lfRow['meetup_location']);
    $itemTitle = htmlspecialchars($lfRow['lost_title'] . ' ↔ ' . $lfRow['found_title']);

    $subject = 'Your UniFind Lost & Found Meetup Has Been Approved!';
    $emailBody = '
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background-color:#F5F2ED;font-family:Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background-color:#F5F2ED;padding:40px 20px;">
<tr><td align="center">
<table width="100%" cellpadding="0" cellspacing="0" style="max-width:500px;background-color:#FFFFFF;border-radius:8px;box-shadow:0 4px 12px rgba(0,0,0,0.08);overflow:hidden;">
<tr><td style="background-color:#6B1010;padding:24px 30px;">
  <p style="margin:0;font-size:22px;font-weight:bold;color:#FFFFFF;">Meetup Approved</p>
  <p style="margin:6px 0 0 0;font-size:13px;color:rgba(255,255,255,0.75);">UniFind, Montclair State University</p>
</td></tr>
<tr><td style="padding:28px 30px;">
  <p style="margin:0 0 16px 0;font-size:15px;color:#000;">Your meetup for <strong>' . $itemTitle . '</strong> has been <strong style="color:#16A34A;">approved</strong> by the UniFind admin team.</p>
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#F9F7F4;border-radius:6px;margin:0 0 20px 0;">
    <tr><td style="padding:16px 20px;">
      <p style="margin:0 0 8px 0;font-size:13px;"><strong>Location:</strong> ' . $location . '</p>
      <p style="margin:0 0 8px 0;font-size:13px;"><strong>Date:</strong> ' . $dateFormatted . '</p>
      <p style="margin:0;font-size:13px;"><strong>Time:</strong> ' . $timeFormatted . '</p>
    </td></tr>
  </table>
  <p style="font-size:13px;color:#444;line-height:1.6;">Please be on time and meet at the agreed location. Stay safe!</p>
  <p style="font-size:12px;color:#8E8E8E;margin-top:32px;">&copy; 2026 UniFind. All rights reserved.</p>
</td></tr>
</table>
</td></tr>
</table>
</body></html>';

    $headers  = "MIME-Version: 1.0\r\n";
    $headers .= "Content-type: text/html; charset=UTF-8\r\n";
    $headers .= "From: UniFind <unifind@ivanovs1.nodomain>\r\n";

    @mail($lfRow['lost_email'],  $subject, $emailBody, $headers);
    @mail($lfRow['found_email'], $subject, $emailBody, $headers);

    api_success(['meetup_id' => $meetupId, 'type' => 'lost_found', 'status' => 'approved']);
} else {
    // Marketplace meetup (existing logic)
    $stmt = $conn->prepare("
        SELECT m.*, b.email AS buyer_email, b.username AS buyer_username,
               s.email AS seller_email, s.username AS seller_username,
               l.title AS item_title
        FROM meetups m
        LEFT JOIN users b ON b.id = m.buyer_id
        LEFT JOIN users s ON s.id = m.seller_id
        LEFT JOIN marketplace_items l ON l.id = m.item_id
        WHERE m.id = ? LIMIT 1
    ");
    if (!$stmt) api_error('Server error.', 500);
    $stmt->bind_param('i', $meetupId);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    if (!$row) api_error('Meetup not found.', 404);

    $status = 'confirmed';
    $upd = $conn->prepare("UPDATE meetups SET status = ? WHERE id = ?");
    if (!$upd) api_error('Server error.', 500);
    $upd->bind_param('si', $status, $meetupId);
    if (!$upd->execute()) api_error('Failed to approve: ' . $upd->error, 500);
    $upd->close();

    $dateFormatted = date('D, M j, Y', strtotime($row['meetup_date']));
    $timeFormatted = date('g:i A', strtotime($row['meetup_time']));
    $location      = htmlspecialchars($row['location']);
    $itemTitle     = htmlspecialchars($row['item_title'] ?? 'your item');

    $subject = 'Your UniFind Meetup Has Been Approved!';
    $emailBody = '
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background-color:#F5F2ED;font-family:Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background-color:#F5F2ED;padding:40px 20px;">
<tr><td align="center">
<table width="100%" cellpadding="0" cellspacing="0" style="max-width:500px;background-color:#FFFFFF;border-radius:8px;box-shadow:0 4px 12px rgba(0,0,0,0.08);overflow:hidden;">
<tr><td style="background-color:#6B1010;padding:24px 30px;">
  <p style="margin:0;font-size:22px;font-weight:bold;color:#FFFFFF;">Meetup Approved</p>
  <p style="margin:6px 0 0 0;font-size:13px;color:rgba(255,255,255,0.75);">UniFind, Montclair State University</p>
</td></tr>
<tr><td style="padding:28px 30px;">
  <p style="margin:0 0 16px 0;font-size:15px;color:#000;">Your meetup for <strong>' . $itemTitle . '</strong> has been <strong style="color:#16A34A;">approved</strong> by the UniFind admin team.</p>
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#F9F7F4;border-radius:6px;margin:0 0 20px 0;">
    <tr><td style="padding:16px 20px;">
      <p style="margin:0 0 8px 0;font-size:13px;"><strong>Location:</strong> ' . $location . '</p>
      <p style="margin:0 0 8px 0;font-size:13px;"><strong>Date:</strong> ' . $dateFormatted . '</p>
      <p style="margin:0;font-size:13px;"><strong>Time:</strong> ' . $timeFormatted . '</p>
    </td></tr>
  </table>
  <p style="font-size:13px;color:#444;line-height:1.6;">Please be on time and meet at the agreed location. Stay safe!</p>
  <p style="font-size:12px;color:#8E8E8E;margin-top:32px;">&copy; 2026 UniFind. All rights reserved.</p>
</td></tr>
</table>
</td></tr>
</table>
</body></html>';

    $headers  = "MIME-Version: 1.0\r\n";
    $headers .= "Content-type: text/html; charset=UTF-8\r\n";
    $headers .= "From: UniFind <unifind@ivanovs1.nodomain>\r\n";

    @mail($row['buyer_email'],  $subject, $emailBody, $headers);
    @mail($row['seller_email'], $subject, $emailBody, $headers);

    api_success(['meetup_id' => $meetupId, 'type' => 'marketplace', 'status' => 'confirmed']);
}
