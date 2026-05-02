<?php
declare(strict_types=1);
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$raw  = file_get_contents('php://input');
$body = $raw ? json_decode($raw, true) : [];

$offerId   = trim($body['offer_id']       ?? '');
$toEmail   = trim($body['buyer_email']    ?? '');
$toName    = trim($body['buyer_name']     ?? 'UniFind User');
$itemTitle = trim($body['item_title']     ?? '');
$itemPrice = isset($body['item_price']) ? number_format((float)$body['item_price'], 2) : '0.00';
$billing   = trim($body['billing_address'] ?? '');
$date      = date('F j, Y \a\t g:i A');

if ($toEmail === '' || $itemTitle === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing buyer_email or item_title']);
    exit;
}

$displayName = $toName !== '' ? $toName : 'there';
$subject = "UniFind Invoice — $itemTitle (\$$itemPrice)";

$html = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>UniFind Invoice</title>
</head>
<body style="margin:0; padding:0; background-color:#F5F2ED; font-family: Helvetica, Arial, sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F5F2ED; padding:40px 20px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:500px; background-color:#FFFFFF; border-radius:8px; box-shadow:0 4px 12px rgba(0,0,0,0.08); overflow:hidden;">
          <tr>
            <td align="center" style="padding:40px 30px 20px 30px;">

              <img src="https://i.imgur.com/wfe6qox.png" alt="UniFind Logo" style="width:220px; height:auto; margin-bottom:30px;">

              <p style="margin:0 0 8px 0; text-align:center; font-size:26px; font-weight:bold; color:#000000;">
                Hi ' . htmlspecialchars($displayName) . '!
              </p>
              <p style="margin:0 0 24px 0; text-align:center; font-size:15px; line-height:1.6; color:#000000;">
                Your payment has been received. It will be processed after your meetup with the seller is marked complete.
              </p>

              <!-- Item block -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px; margin-bottom:24px;">
                <tr>
                  <td style="padding:18px 20px;">
                    <p style="margin:0 0 6px 0; font-size:16px; font-weight:bold; color:#000000;">' . htmlspecialchars($itemTitle) . '</p>
                    <p style="margin:0; font-size:26px; font-weight:900; color:#DD2635;">$' . htmlspecialchars($itemPrice) . '</p>
                  </td>
                </tr>
              </table>

              <!-- Details table -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="font-size:13px; color:#555555; margin-bottom:24px;">
                <tr>
                  <td style="padding:8px 0; border-bottom:1px solid #E8E4DE; font-weight:bold; color:#000000; width:40%;">Reference</td>
                  <td style="padding:8px 0; border-bottom:1px solid #E8E4DE; text-align:right; color:#333333;">' . htmlspecialchars($offerId) . '</td>
                </tr>
                <tr>
                  <td style="padding:8px 0; border-bottom:1px solid #E8E4DE; font-weight:bold; color:#000000;">Date</td>
                  <td style="padding:8px 0; border-bottom:1px solid #E8E4DE; text-align:right; color:#333333;">' . htmlspecialchars($date) . '</td>
                </tr>
                <tr>
                  <td style="padding:8px 0; font-weight:bold; color:#000000;">Billing</td>
                  <td style="padding:8px 0; text-align:right; color:#333333;">' . htmlspecialchars($billing) . '</td>
                </tr>
              </table>

              <p style="margin:0 0 40px 0; font-size:13px; color:#8E8E8E; text-align:center;">
                Questions? Contact us through the UniFind app.
              </p>

              <p style="color:#8E8E8E; font-size:12px; line-height:1.4; margin:0; text-align:center;">
                &copy; 2026 UniFind &mdash; Montclair State University Campus Marketplace
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
$headers .= "Content-Type: text/html; charset=UTF-8\r\n";
$headers .= "From: UniFind <noreply@ivanovs1.cpanelhosting.com>\r\n";
$headers .= "Reply-To: noreply@ivanovs1.cpanelhosting.com\r\n";

$sent = mail($toEmail, $subject, $html, $headers);
echo json_encode(['success' => true, 'sent' => $sent]);