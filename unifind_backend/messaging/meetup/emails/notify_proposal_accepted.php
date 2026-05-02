<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit();
require_once __DIR__ . '/../../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit();
}

$body     = json_decode(file_get_contents('php://input'), true) ?: [];
$meetupId = (int)($body['meetup_id'] ?? 0);

if ($meetupId <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Invalid meetup ID']);
    exit();
}

$stmt = $conn->prepare("
    SELECT m.meetup_date, m.meetup_time, m.location,
           u_buyer.first_name  AS buyer_first,
           u_buyer.email       AS buyer_email,
           u_seller.first_name AS seller_first
    FROM meetups m
    JOIN users u_buyer  ON u_buyer.id  = m.buyer_id
    JOIN users u_seller ON u_seller.id = m.seller_id
    WHERE m.meetup_id = ?
    LIMIT 1
");
$stmt->bind_param('i', $meetupId);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
$conn->close();

if (!$row) {
    echo json_encode(['success' => false, 'error' => 'Meetup not found']);
    exit();
}

$buyerName  = $row['buyer_first']  ?? 'there';
$sellerName = $row['seller_first'] ?? 'The other user';
$to         = $row['buyer_email'];

$dateObj = DateTime::createFromFormat('Y-m-d', $row['meetup_date']);
$dayNum  = $dateObj->format('j');
$dayInt  = (int)$dayNum;
if ($dayInt === 11 || $dayInt === 12 || $dayInt === 13) {
    $suffix = 'th';
} elseif ($dayInt % 10 === 1) {
    $suffix = 'st';
} elseif ($dayInt % 10 === 2) {
    $suffix = 'nd';
} elseif ($dayInt % 10 === 3) {
    $suffix = 'rd';
} else {
    $suffix = 'th';
}
$formattedDate = $dateObj->format('l') . ', ' . $dateObj->format('F') . ' ' . $dayNum . $suffix;

$timeObj       = DateTime::createFromFormat('H:i:s', $row['meetup_time']);
$formattedTime = $timeObj->format('g:i A');

$subject = "✅ Your meetup proposal was accepted!";

$emailBody = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Meetup Proposal Accepted</title>
</head>
<body style="margin:0; padding:0; background-color:#F5F2ED; font-family: Helvetica, Arial, sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F5F2ED; padding:40px 20px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:500px; background-color:#FFFFFF; border-radius:8px; box-shadow:0 4px 12px rgba(0,0,0,0.08); overflow:hidden;">
          <tr>
            <td align="center" style="padding:40px 30px;">
              <img src="https://i.imgur.com/wfe6qox.png" alt="UniFind Logo" style="width:220px; height:auto; margin-bottom:30px;">
              <p style="margin:0 0 8px 0; text-align:center; font-size:26px; font-weight:bold; color:#000000;">
                Hi ' . htmlspecialchars($buyerName) . '!
              </p>
              <p style="margin:0 0 20px 0; text-align:center; font-size:16px; line-height:1.6; color:#000000;">
                Great news! <strong>' . htmlspecialchars($sellerName) . '</strong> has accepted your meetup proposal.
              </p>
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px; padding:15px; margin:0 0 20px 0;">
                <tr><td style="padding:8px 15px; font-size:15px; color:#000000;">📅 <strong>Date:</strong> ' . htmlspecialchars($formattedDate) . '</td></tr>
                <tr><td style="padding:8px 15px; font-size:15px; color:#000000;">🕐 <strong>Time:</strong> ' . htmlspecialchars($formattedTime) . '</td></tr>
                <tr><td style="padding:8px 15px; font-size:15px; color:#000000;">📍 <strong>Location:</strong> ' . htmlspecialchars($row['location']) . ', MSU</td></tr>
              </table>
              <p style="margin:0 0 20px 0; text-align:center; font-size:16px; line-height:1.6; color:#000000;">
                Your meetup has been sent to the UniFind admin team for final approval. You will be notified once it has been reviewed!
              </p>
              <p style="color:#8E8E8E; font-size:13px; line-height:1.6; margin:0 0 40px 0; text-align:center;">
                Thank you for using UniFind!
              </p>
              <p style="color:#8E8E8E; font-size:12px; line-height:1.4; margin-top:40px; text-align:center;">
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
$sent = @mail($to, $subject, $emailBody, $headers);
echo json_encode(['success' => $sent]);
?>