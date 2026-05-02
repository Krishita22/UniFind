<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';
date_default_timezone_set('America/New_York');
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
if (!$meetupId) api_error('meetup_id required.');

// Try marketplace first
$stmt = $conn->prepare("
    SELECT m.*,
           b.email AS buyer_email,  b.username AS buyer_username,  b.first_name AS buyer_first,
           s.email AS seller_email, s.username AS seller_username, s.first_name AS seller_first,
           mi.title AS item_title
    FROM meetups m
    LEFT JOIN users b  ON b.id = m.buyer_id
    LEFT JOIN users s  ON s.id = m.seller_id
    LEFT JOIN marketplace_items mi ON mi.id = m.item_id
    WHERE m.meetup_id = ? LIMIT 1
");
if (!$stmt) api_error('Server error: ' . $conn->error, 500);
$stmt->bind_param('i', $meetupId);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

$isLostFound = false;

if (!$row) {
    // Try lost & found
    $stmt2 = $conn->prepare("
        SELECT m.id AS meetup_id, m.status, m.meetup_date, m.meetup_time,
               m.meetup_location AS location, NULL AS item_id,
               u_lost.email  AS buyer_email,  u_lost.username  AS buyer_username,  u_lost.first_name  AS buyer_first,
               u_found.email AS seller_email, u_found.username AS seller_username, u_found.first_name AS seller_first,
               CONCAT(li.title, ' & ', fi.title) AS item_title
        FROM lost_found_meetups m
        JOIN lost_found_matches lm ON m.match_id = lm.id
        LEFT JOIN lost_found_items li ON lm.lost_item_id = li.id
        LEFT JOIN lost_found_items fi ON lm.matched_found_item_id = fi.id
        LEFT JOIN users u_lost  ON li.poster_id = u_lost.id
        LEFT JOIN users u_found ON fi.poster_id = u_found.id
        WHERE m.id = ? LIMIT 1
    ");
    if (!$stmt2) api_error('Server error.', 500);
    $stmt2->bind_param('i', $meetupId);
    $stmt2->execute();
    $row = $stmt2->get_result()->fetch_assoc();
    $stmt2->close();
    if (!$row) api_error('Meetup not found.', 404);
    $isLostFound = true;
}

// Mark as completed
if ($isLostFound) {
    $upd = $conn->prepare("UPDATE lost_found_meetups SET status = 'completed' WHERE id = ?");
} else {
    $upd = $conn->prepare("UPDATE meetups SET status = 'completed' WHERE meetup_id = ?");
}
$upd->bind_param('i', $meetupId);
$upd->execute();
$upd->close();

$isMarketplace    = !$isLostFound && !empty($row['item_id']);
$paymentProcessed = false;

// Only mark sold + process payment if a pending payment offer exists
if ($isMarketplace) {
    $chk = $conn->prepare("SELECT id FROM payment_offers WHERE listing_id = ? AND status = 'pending' LIMIT 1");
    $chk->bind_param('i', $row['item_id']);
    $chk->execute();
    $hasPayment = $chk->get_result()->fetch_assoc();
    $chk->close();

    if ($hasPayment) {
        $sold = $conn->prepare("UPDATE marketplace_items SET status = 'sold' WHERE id = ?");
        $sold->bind_param('i', $row['item_id']);
        $sold->execute();
        $sold->close();

        $pay = $conn->prepare("UPDATE payment_offers SET status = 'completed' WHERE listing_id = ? AND status = 'pending'");
        $pay->bind_param('i', $row['item_id']);
        $pay->execute();
        $pay->close();

        $paymentProcessed = true;
    }
}

// Prepare shared email values
$dateFormatted = date('D, M j, Y', strtotime($row['meetup_date']));
$timeFormatted = date('g:i A',     strtotime($row['meetup_time']));
$location      = htmlspecialchars($row['location'] ?? '');
$itemTitle     = htmlspecialchars($row['item_title'] ?? 'your item');

$subject = 'Your UniFind Meetup Is Complete!';

$paymentNote = $paymentProcessed
    ? 'The payment for this transaction has been processed. Thank you for using UniFind!'
    : 'Your meetup has been completed successfully. Thank you for using UniFind!';

foreach ([
    ['email' => $row['buyer_email'],  'name' => $row['buyer_first']  ?: $row['buyer_username']],
    ['email' => $row['seller_email'], 'name' => $row['seller_first'] ?: $row['seller_username']],
] as $recipient) {
    if (empty($recipient['email'])) continue;

    $name = htmlspecialchars($recipient['name'] ?? 'there');

    $emailHtml = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Meetup Complete</title>
</head>
<body style="margin:0; padding:0; background-color:#F5F2ED; font-family: Helvetica, Arial, sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F5F2ED; padding:40px 20px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:500px; background-color:#FFFFFF; border-radius:8px; box-shadow:0 4px 12px rgba(0,0,0,0.08); overflow:hidden;">
          <tr>
            <td align="center" style="padding:40px 30px 36px 30px;">

              <img src="https://i.imgur.com/wfe6qox.png" alt="UniFind Logo" style="width:220px; height:auto; margin-bottom:30px;">

              <p style="margin:0 0 8px 0; text-align:center; font-size:26px; font-weight:bold; color:#000000;">
                Hi ' . $name . '!
              </p>
              <p style="margin:0 0 24px 0; text-align:center; font-size:15px; line-height:1.6; color:#000000;">
                Your meetup has been marked as <strong style="color:#16A34A;">completed</strong> by the UniFind team.
              </p>

              <!-- Item block -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px; margin-bottom:20px;">
                <tr>
                  <td style="padding:18px 20px;">
                    <p style="margin:0 0 4px 0; font-size:12px; font-weight:bold; color:#8E8E8E; text-transform:uppercase; letter-spacing:0.5px;">Item</p>
                    <p style="margin:0; font-size:17px; font-weight:bold; color:#000000;">' . $itemTitle . '</p>
                  </td>
                </tr>
              </table>

              <!-- Meetup details block -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F9F7F4; border-left:4px solid #8E8E8E; border-radius:4px; margin-bottom:24px;">
                <tr>
                  <td style="padding:18px 20px;">
                    <p style="margin:0 0 4px 0; font-size:12px; font-weight:bold; color:#8E8E8E; text-transform:uppercase; letter-spacing:0.5px;">Meetup Details</p>
                    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="font-size:13px; color:#333333; margin-top:8px;">
                      <tr>
                        <td style="padding:4px 0; font-weight:bold; color:#000000; width:30%;">Location</td>
                        <td style="padding:4px 0;">' . $location . '</td>
                      </tr>
                      <tr>
                        <td style="padding:4px 0; font-weight:bold; color:#000000;">Date</td>
                        <td style="padding:4px 0;">' . $dateFormatted . '</td>
                      </tr>
                      <tr>
                        <td style="padding:4px 0; font-weight:bold; color:#000000;">Time</td>
                        <td style="padding:4px 0;">' . $timeFormatted . '</td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>

              <p style="margin:0 0 24px 0; text-align:center; font-size:14px; line-height:1.7; color:#333333;">
                ' . htmlspecialchars($paymentNote) . '
              </p>

              <p style="color:#8E8E8E; font-size:12px; line-height:1.4; margin:0; text-align:center;">
                &copy; 2026 UniFind. All rights reserved.
              </p>

            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
';

    $headers  = "MIME-Version: 1.0\r\n";
    $headers .= "Content-type: text/html; charset=UTF-8\r\n";
    $headers .= "From: UniFind <unifind@ivanovs1.nodomain>\r\n";
    @mail($recipient['email'], $subject, $emailHtml, $headers);
}

api_success([
    'meetup_id'         => $meetupId,
    'status'            => 'completed',
    'is_marketplace'    => $isMarketplace,
    'payment_processed' => $paymentProcessed,
]);