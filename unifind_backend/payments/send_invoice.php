<?php
declare(strict_types=1);
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$raw  = file_get_contents('php://input');
$body = $raw ? json_decode($raw, true) : [];

$offerId   = trim($body['offer_id']    ?? '');
$toEmail   = trim($body['buyer_email'] ?? '');
$toName    = trim($body['buyer_name']  ?? 'UniFind User');
$itemTitle = trim($body['item_title']  ?? '');
$itemPrice = isset($body['item_price']) ? number_format((float)$body['item_price'], 2) : '0.00';
$billing   = trim($body['billing_address'] ?? '');
$date      = date('F j, Y \a\t g:i A');

if ($toEmail === '' || $itemTitle === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing buyer_email or item_title']);
    exit;
}

$subject = "UniFind Invoice — $itemTitle (\$$itemPrice)";

$html = "
<html><body style='font-family:sans-serif;background:#f6f9fc;padding:20px'>
<div style='max-width:520px;margin:auto;background:#fff;border-radius:12px;overflow:hidden;border:1px solid #e3e8ee'>
  <div style='background:#8B1A1A;padding:24px 32px'>
    <h1 style='margin:0;color:#fff;font-size:22px'>UniFind</h1>
    <p style='margin:4px 0 0;color:rgba(255,255,255,0.7);font-size:13px'>Payment Invoice</p>
  </div>
  <div style='padding:28px 32px'>
    <p style='font-size:15px;font-weight:bold;color:#1a1010'>Hi $toName,</p>
    <p style='font-size:13px;color:#9c7070;line-height:1.7'>
      Your payment details have been received. Payment will be processed after your meetup with the seller is marked complete.
    </p>
    <div style='background:#fcf8f8;border:1px solid #edd8d8;border-radius:8px;padding:18px;margin:20px 0'>
      <p style='margin:0 0 4px;font-size:16px;font-weight:bold;color:#1a1010'>$itemTitle</p>
      <p style='margin:8px 0 0;font-size:22px;font-weight:900;color:#8B1A1A'>\$$itemPrice</p>
    </div>
    <table style='width:100%;font-size:13px;color:#9c7070'>
      <tr><td style='padding:6px 0;border-bottom:1px solid #edd8d8'><b>Reference</b></td><td align='right' style='padding:6px 0;border-bottom:1px solid #edd8d8;color:#1a1010'>$offerId</td></tr>
      <tr><td style='padding:6px 0;border-bottom:1px solid #edd8d8'><b>Date</b></td><td align='right' style='padding:6px 0;border-bottom:1px solid #edd8d8;color:#1a1010'>$date</td></tr>
      <tr><td style='padding:6px 0'><b>Billing</b></td><td align='right' style='padding:6px 0;color:#1a1010'>$billing</td></tr>
    </table>
    <p style='font-size:12px;color:#9c7070;margin-top:20px'>Questions? Contact us through the UniFind app.</p>
  </div>
  <div style='background:#fcf8f8;border-top:1px solid #edd8d8;padding:16px 32px;text-align:center'>
    <p style='margin:0;font-size:12px;color:#9c7070'>UniFind &mdash; Montclair State University Campus Marketplace</p>
  </div>
</div>
</body></html>";

$headers  = "MIME-Version: 1.0\r\n";
$headers .= "Content-Type: text/html; charset=UTF-8\r\n";
$headers .= "From: UniFind <noreply@ivanovs1.cpanelhosting.com>\r\n";
$headers .= "Reply-To: noreply@ivanovs1.cpanelhosting.com\r\n";

$sent = mail($toEmail, $subject, $html, $headers);
echo json_encode(['success' => true, 'sent' => $sent]);
