<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../PHPMailer/src/Exception.php';
require_once __DIR__ . '/../PHPMailer/src/PHPMailer.php';
require_once __DIR__ . '/../PHPMailer/src/SMTP.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
    function api_body(): array { $raw = file_get_contents('php://input'); if ($raw === false || $raw === '') return []; $decoded = json_decode($raw, true); return is_array($decoded) ? $decoded : []; }
}

$body    = api_body();
$offerId = trim($body['offer_id'] ?? '');
$userId  = isset($body['user_id']) ? (int)$body['user_id'] : 0;

if ($offerId === '' || $userId <= 0) {
    api_error('Missing required fields: offer_id, user_id.');
}

// ── fetch offer before updating ───────────────────────────────────────────────
$sel = $conn->prepare(
    'SELECT offer_id, amount, buyer_name, buyer_email, billing_address, item_title, created_at
     FROM payment_offers WHERE offer_id = ? AND (buyer_id = ? OR seller_id = ?) AND status = \'pending\''
);
if (!$sel) { api_error('Server error.', 500); }
$sel->bind_param('sii', $offerId, $userId, $userId);
$sel->execute();
$offer = $sel->get_result()->fetch_assoc();
$sel->close();

if (!$offer) {
    api_error('Offer not found or already processed.');
}

// ── mark completed ────────────────────────────────────────────────────────────
$upd = $conn->prepare('UPDATE payment_offers SET status = \'completed\', updated_at = NOW() WHERE offer_id = ?');
if (!$upd) { api_error('Server error.', 500); }
$upd->bind_param('s', $offerId);
if (!$upd->execute()) { $upd->close(); api_error('Failed to process payment.', 500); }
$upd->close();

// ── send confirmation email ───────────────────────────────────────────────────
$buyerEmail     = $offer['buyer_email']     ?? '';
$buyerName      = $offer['buyer_name']      !== '' ? $offer['buyer_name'] : 'UniFind User';
$itemTitle      = $offer['item_title']      !== '' ? $offer['item_title'] : 'Marketplace Item';
$amount         = number_format((float)($offer['amount'] ?? 0), 2);
$billingAddress = $offer['billing_address'] ?? '';
$processedAt    = date('F j, Y \a\t g:i A');
$invoiceRef     = $offerId;

if ($buyerEmail !== '') {
    $htmlBody = <<<HTML
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#f6f9fc;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f6f9fc;padding:40px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:12px;overflow:hidden;border:1px solid #e3e8ee;">

        <!-- Header -->
        <tr>
          <td style="background:linear-gradient(135deg,#8B1A1A,#7A1A1A);padding:28px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;letter-spacing:-0.5px;">UniFind</h1>
            <p style="margin:6px 0 0;color:rgba(255,255,255,0.65);font-size:13px;">Payment Confirmation</p>
          </td>
        </tr>

        <!-- Success badge -->
        <tr>
          <td style="padding:32px 40px 0;text-align:center;">
            <div style="display:inline-block;background:#f0fdf4;border:1.5px solid #86efac;border-radius:50px;padding:8px 20px;">
              <span style="font-size:13px;font-weight:800;color:#16a34a;">&#10003;&nbsp; Payment Complete</span>
            </div>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style="padding:24px 40px 32px;">
            <p style="margin:0 0 8px;font-size:16px;color:#1a1010;font-weight:700;">Hi {$buyerName},</p>
            <p style="margin:0 0 28px;font-size:14px;color:#9c7070;line-height:1.7;">
              Your payment has been successfully processed after your meetup was marked complete. Here is your receipt.
            </p>

            <!-- Receipt card -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#fcf8f8;border:1px solid #edd8d8;border-radius:10px;margin-bottom:28px;">
              <tr>
                <td style="padding:20px 24px;">
                  <p style="margin:0 0 4px;font-size:17px;font-weight:800;color:#1a1010;">{$itemTitle}</p>
                  <table width="100%" cellpadding="0" cellspacing="0" style="margin-top:16px;">
                    <tr>
                      <td style="font-size:13px;color:#9c7070;font-weight:600;padding-bottom:8px;">Amount Charged</td>
                      <td align="right" style="font-size:24px;font-weight:900;color:#8B1A1A;">\${$amount}</td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>

            <!-- Details -->
            <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:28px;">
              <tr>
                <td style="padding:10px 0;border-bottom:1px solid #edd8d8;font-size:13px;color:#9c7070;font-weight:600;">Invoice Reference</td>
                <td align="right" style="padding:10px 0;border-bottom:1px solid #edd8d8;font-size:13px;color:#1a1010;font-weight:700;">{$invoiceRef}</td>
              </tr>
              <tr>
                <td style="padding:10px 0;border-bottom:1px solid #edd8d8;font-size:13px;color:#9c7070;font-weight:600;">Processed</td>
                <td align="right" style="padding:10px 0;border-bottom:1px solid #edd8d8;font-size:13px;color:#1a1010;font-weight:700;">{$processedAt}</td>
              </tr>
              <tr>
                <td style="padding:10px 0;border-bottom:1px solid #edd8d8;font-size:13px;color:#9c7070;font-weight:600;">Billing Address</td>
                <td align="right" style="padding:10px 0;border-bottom:1px solid #edd8d8;font-size:13px;color:#1a1010;font-weight:700;">{$billingAddress}</td>
              </tr>
              <tr>
                <td style="padding:10px 0;font-size:13px;color:#9c7070;font-weight:600;">Status</td>
                <td align="right" style="padding:10px 0;font-size:13px;font-weight:800;color:#16a34a;">Completed</td>
              </tr>
            </table>

            <p style="margin:0;font-size:12px;color:#9c7070;line-height:1.7;">
              Thank you for using UniFind. If you have any questions, reach us through the app.
            </p>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style="background:#fcf8f8;border-top:1px solid #edd8d8;padding:20px 40px;text-align:center;">
            <p style="margin:0;font-size:12px;color:#9c7070;">UniFind &mdash; Montclair State University Campus Marketplace</p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>
HTML;

    $altBody = "Hi {$buyerName},\n\n"
        . "Your payment for \"{$itemTitle}\" (\${$amount}) has been successfully processed.\n\n"
        . "Invoice Reference: {$invoiceRef}\n"
        . "Processed: {$processedAt}\n"
        . "Status: Completed\n\n"
        . "Thank you for using UniFind.\n"
        . "— UniFind Team";

    try {
        $mail = new PHPMailer\PHPMailer\PHPMailer(true);
        $mail->isSMTP();
        $mail->Host       = $config['smtp_host']   ?? $config['mail']['smtp_host']   ?? '';
        $mail->SMTPAuth   = true;
        $mail->Username   = $config['smtp_user']   ?? $config['mail']['smtp_user']   ?? '';
        $mail->Password   = $config['smtp_pass']   ?? $config['mail']['smtp_pass']   ?? '';
        $mail->Port       = (int)($config['smtp_port']   ?? $config['mail']['smtp_port']   ?? 587);
        $mail->SMTPSecure = $config['smtp_secure'] ?? $config['mail']['smtp_secure'] ?? 'tls';
        $mail->setFrom(
            $config['from_email'] ?? $config['mail']['from_email'] ?? 'noreply@unifind.app',
            $config['from_name']  ?? $config['mail']['from_name']  ?? 'UniFind'
        );
        $mail->addAddress($buyerEmail, $buyerName);
        $mail->isHTML(true);
        $mail->Subject = "UniFind Payment Confirmed — {$itemTitle} (\${$amount})";
        $mail->Body    = $htmlBody;
        $mail->AltBody = $altBody;
        $mail->send();
    } catch (Exception $e) {
        error_log('process_payment mailer error: ' . ($mail->ErrorInfo ?? $e->getMessage()));
    }
}

api_success([
    'offer_id'     => $offerId,
    'status'       => 'completed',
    'processed_at' => date('Y-m-d H:i:s'),
]);
