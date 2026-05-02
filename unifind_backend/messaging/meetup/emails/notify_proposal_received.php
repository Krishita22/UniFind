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

$body        = json_decode(file_get_contents('php://input'), true) ?: [];
$sellerEmail = trim($body['seller_email'] ?? '');
$sellerName  = trim($body['seller_name']  ?? 'there');
$meetupDate  = trim($body['meetup_date']  ?? '');
$meetupTime  = trim($body['meetup_time']  ?? '');
$location    = trim($body['location']     ?? '');

$buyerName = trim($body['buyer_name'] ?? '');
if (empty($buyerName)) {
    $buyerId = (int)($body['buyer_id'] ?? 0);
    if ($buyerId > 0) {
        $stmt = $conn->prepare("SELECT first_name FROM users WHERE id = ? LIMIT 1");
        $stmt->bind_param('i', $buyerId);
        $stmt->execute();
        $row2 = $stmt->get_result()->fetch_assoc();
        $stmt->close();
        $buyerName = $row2['first_name'] ?? 'A student';
    }
}

$dateObj = DateTime::createFromFormat('Y-m-d', $meetupDate);
$day     = $dateObj->format('l');
$month   = $dateObj->format('F');
$dayNum  = $dateObj->format('j');
$dayInt = (int)$dayNum;
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
$formattedDate = "$day, $month $dayNum$suffix";

$timeObj       = DateTime::createFromFormat('H:i:s', $meetupTime);
$formattedTime = $timeObj->format('g:i A');

if (empty($sellerEmail)) {
    echo json_encode(['success' => false, 'error' => 'No email address']);
    exit();
}

$to      = $sellerEmail;
$subject = "📍 You have a new meetup proposal from $buyerName!";

$emailBody = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>New Meetup Proposal</title>
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
                Hi ' . htmlspecialchars($sellerName) . '!
              </p>
              <p style="margin:0 0 20px 0; text-align:center; font-size:16px; line-height:1.6; color:#000000;">
                <strong>' . htmlspecialchars($buyerName) . '</strong> has proposed a meetup with you!
              </p>
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px; padding:15px; margin:0 0 20px 0;">
                <tr><td style="padding:8px 15px; font-size:15px; color:#000000;">📅 <strong>Date:</strong> ' . htmlspecialchars($formattedDate) . '</td></tr>
                <tr><td style="padding:8px 15px; font-size:15px; color:#000000;">🕐 <strong>Time:</strong> ' . htmlspecialchars($formattedTime) . '</td></tr>
                <tr><td style="padding:8px 15px; font-size:15px; color:#000000;">📍 <strong>Location:</strong> ' . htmlspecialchars($location) . ', MSU</td></tr>
              </table>
              <p style="margin:0 0 20px 0; text-align:center; font-size:16px; line-height:1.6; color:#000000;">
                Please log in to UniFind to accept or decline this proposal.
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