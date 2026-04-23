<?php
declare(strict_types=1);
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once __DIR__ . '/../config.php';

$raw  = file_get_contents('php://input');
$body = $raw ? json_decode($raw, true) : [];

$offerId = trim($body['offer_id'] ?? '');
$userId  = isset($body['user_id']) ? (int)$body['user_id'] : 0;

if ($offerId === '' || $userId <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing offer_id or user_id']);
    exit;
}

$sel = $conn->prepare(
    'SELECT offer_id, amount, buyer_name, buyer_email, billing_address, item_title
     FROM payment_offers WHERE offer_id = ? AND (buyer_id = ? OR seller_id = ?) AND status = \'pending\''
);
if (!$sel) { http_response_code(500); echo json_encode(['success'=>false,'error'=>'Server error']); exit; }
$sel->bind_param('sii', $offerId, $userId, $userId);
$sel->execute();
$offer = $sel->get_result()->fetch_assoc();
$sel->close();

if (!$offer) {
    http_response_code(404);
    echo json_encode(['success' => false, 'error' => 'Offer not found or already processed']);
    exit;
}

$upd = $conn->prepare('UPDATE payment_offers SET status = \'completed\', updated_at = NOW() WHERE offer_id = ?');
if (!$upd) { http_response_code(500); echo json_encode(['success'=>false,'error'=>'Server error']); exit; }
$upd->bind_param('s', $offerId);
if (!$upd->execute()) { $upd->close(); http_response_code(500); echo json_encode(['success'=>false,'error'=>'Failed to process payment']); exit; }
$upd->close();

$toEmail   = $offer['buyer_email'] ?? '';
$toName    = ($offer['buyer_name'] !== '') ? $offer['buyer_name'] : 'UniFind User';
$itemTitle = ($offer['item_title'] !== '') ? $offer['item_title'] : 'Marketplace Item';
$amount    = number_format((float)($offer['amount'] ?? 0), 2);
$billing   = $offer['billing_address'] ?? '';
$date      = date('F j, Y \a\t g:i A');

if ($toEmail !== '') {
    $subject = "UniFind Payment Confirmed — $itemTitle (\$$amount)";

    $html = "
<html><body style='font-family:sans-serif;background:#f6f9fc;padding:20px'>
<div style='max-width:520px;margin:auto;background:#fff;border-radius:12px;overflow:hidden;border:1px solid #e3e8ee'>
  <div style='background:#8B1A1A;padding:24px 32px'>
    <h1 style='margin:0;color:#fff;font-size:22px'>UniFind</h1>
    <p style='margin:4px 0 0;color:rgba(255,255,255,0.7);font-size:13px'>Payment Confirmation</p>
  </div>
  <div style='padding:28px 32px'>
    <div style='background:#f0fdf4;border:1px solid #86efac;border-radius:50px;display:inline-block;padding:6px 18px;margin-bottom:16px'>
      <span style='font-size:13px;font-weight:bold;color:#16a34a'>&#10003; Payment Complete</span>
    </div>
    <p style='font-size:15px;font-weight:bold;color:#1a1010'>Hi $toName,</p>
    <p style='font-size:13px;color:#9c7070;line-height:1.7'>
      Your payment has been successfully processed. Here is your receipt.
    </p>
    <div style='background:#fcf8f8;border:1px solid #edd8d8;border-radius:8px;padding:18px;margin:20px 0'>
      <p style='margin:0 0 4px;font-size:16px;font-weight:bold;color:#1a1010'>$itemTitle</p>
      <p style='margin:8px 0 0;font-size:22px;font-weight:900;color:#8B1A1A'>\$$amount</p>
    </div>
    <table style='width:100%;font-size:13px;color:#9c7070'>
      <tr><td style='padding:6px 0;border-bottom:1px solid #edd8d8'><b>Reference</b></td><td align='right' style='padding:6px 0;border-bottom:1px solid #edd8d8;color:#1a1010'>$offerId</td></tr>
      <tr><td style='padding:6px 0;border-bottom:1px solid #edd8d8'><b>Processed</b></td><td align='right' style='padding:6px 0;border-bottom:1px solid #edd8d8;color:#1a1010'>$date</td></tr>
      <tr><td style='padding:6px 0;border-bottom:1px solid #edd8d8'><b>Billing</b></td><td align='right' style='padding:6px 0;border-bottom:1px solid #edd8d8;color:#1a1010'>$billing</td></tr>
      <tr><td style='padding:6px 0'><b>Status</b></td><td align='right' style='padding:6px 0;font-weight:bold;color:#16a34a'>Completed</td></tr>
    </table>
    <p style='font-size:12px;color:#9c7070;margin-top:20px'>Thank you for using UniFind.</p>
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

    mail($toEmail, $subject, $html, $headers);
}

echo json_encode([
    'success'      => true,
    'data'         => ['offer_id' => $offerId, 'status' => 'completed', 'processed_at' => date('Y-m-d H:i:s')],
]);
