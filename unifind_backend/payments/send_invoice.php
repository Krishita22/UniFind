<?php
declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../PHPMailer/src/Exception.php';
require_once __DIR__ . '/../PHPMailer/src/PHPMailer.php';
require_once __DIR__ . '/../PHPMailer/src/SMTP.php';

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
    function api_body(): array { $raw = file_get_contents('php://input'); if ($raw === false || $raw === '') return []; $decoded = json_decode($raw, true); return is_array($decoded) ? $decoded : []; }
}

$body           = api_body();
$offerId        = trim($body['offer_id']       ?? '');
$buyerEmail     = trim($body['buyer_email']    ?? '');
$buyerName      = trim($body['buyer_name']     ?? 'UniFind User');
$itemTitle      = trim($body['item_title']     ?? '');
$itemPrice      = isset($body['item_price'])   ? (float)$body['item_price'] : 0.0;
$itemCategory   = trim($body['item_category']  ?? '');
$itemCondition  = trim($body['item_condition'] ?? '');
$itemImage      = trim($body['item_image']     ?? '');
$billingAddress = trim($body['billing_address'] ?? '');

if ($buyerEmail === '' || $itemTitle === '' || $itemPrice <= 0) {
    api_error('Missing required fields: buyer_email, item_title, item_price.');
}

$date           = date('F j, Y');
$time           = date('g:i A');
$priceFormatted = number_format($itemPrice, 2);
$imageHtml      = $itemImage !== ''
    ? '<img src="' . htmlspecialchars($itemImage) . '" alt="' . htmlspecialchars($itemTitle) . '" style="width:100%;max-width:320px;border-radius:8px;margin-bottom:16px;">'
    : '';

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
          <td style="background:#0a2540;padding:28px 40px;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;letter-spacing:-0.5px;">UniFind</h1>
            <p style="margin:4px 0 0;color:rgba(255,255,255,0.6);font-size:13px;font-weight:500;">Payment Invoice</p>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style="padding:32px 40px;">
            <p style="margin:0 0 8px;font-size:16px;color:#1a1a2e;font-weight:700;">Hi {$buyerName},</p>
            <p style="margin:0 0 28px;font-size:14px;color:#697386;line-height:1.7;">
              Your payment details for the item below have been received. Your payment will be processed once the meetup with the seller is marked as completed.
            </p>

            <!-- Item card -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#f6f9fc;border:1px solid #e3e8ee;border-radius:10px;margin-bottom:28px;">
              <tr>
                <td style="padding:20px 24px;">
                  {$imageHtml}
                  <p style="margin:0 0 4px;font-size:17px;font-weight:800;color:#1a1a2e;">{$itemTitle}</p>
                  <p style="margin:0 0 16px;font-size:13px;color:#697386;">{$itemCategory} &middot; {$itemCondition}</p>
                  <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                      <td style="font-size:13px;color:#697386;font-weight:600;">Amount</td>
                      <td align="right" style="font-size:24px;font-weight:900;color:#0a2540;">\${$priceFormatted}</td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>

            <!-- Details -->
            <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:28px;">
              <tr>
                <td style="padding:10px 0;border-bottom:1px solid #e3e8ee;font-size:13px;color:#8898aa;font-weight:600;">Invoice Reference</td>
                <td align="right" style="padding:10px 0;border-bottom:1px solid #e3e8ee;font-size:13px;color:#1a1a2e;font-weight:700;">{$offerId}</td>
              </tr>
              <tr>
                <td style="padding:10px 0;border-bottom:1px solid #e3e8ee;font-size:13px;color:#8898aa;font-weight:600;">Date</td>
                <td align="right" style="padding:10px 0;border-bottom:1px solid #e3e8ee;font-size:13px;color:#1a1a2e;font-weight:700;">{$date} at {$time}</td>
              </tr>
              <tr>
                <td style="padding:10px 0;border-bottom:1px solid #e3e8ee;font-size:13px;color:#8898aa;font-weight:600;">Billing Address</td>
                <td align="right" style="padding:10px 0;border-bottom:1px solid #e3e8ee;font-size:13px;color:#1a1a2e;font-weight:700;">{$billingAddress}</td>
              </tr>
              <tr>
                <td style="padding:10px 0;font-size:13px;color:#8898aa;font-weight:600;">Status</td>
                <td align="right" style="padding:10px 0;font-size:13px;font-weight:800;color:#d97706;">Pending &mdash; awaiting meetup</td>
              </tr>
            </table>

            <!-- Next steps -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;margin-bottom:28px;">
              <tr>
                <td style="padding:18px 22px;">
                  <p style="margin:0 0 10px;font-size:13px;font-weight:800;color:#1e40af;">What happens next</p>
                  <ol style="margin:0;padding-left:18px;font-size:13px;color:#1e40af;line-height:2.2;">
                    <li>Arrange a meeting with the seller via UniFind Messages.</li>
                    <li>Meet up and exchange the item.</li>
                    <li>Mark the meeting as completed &mdash; your payment will be processed.</li>
                    <li>A payment confirmation email will be sent to you.</li>
                  </ol>
                </td>
              </tr>
            </table>

            <p style="margin:0;font-size:12px;color:#8898aa;line-height:1.7;">
              Questions? Contact us through the UniFind app.
            </p>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style="background:#f6f9fc;border-top:1px solid #e3e8ee;padding:20px 40px;text-align:center;">
            <p style="margin:0;font-size:12px;color:#8898aa;">UniFind &mdash; Montclair State University Campus Marketplace</p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>
HTML;

$altBody = "Hi {$buyerName},\n\n"
    . "Your payment for \"{$itemTitle}\" (\${$priceFormatted}) has been received.\n\n"
    . "Invoice Reference: {$offerId}\n"
    . "Date: {$date} at {$time}\n"
    . "Status: Pending — awaiting meetup completion\n\n"
    . "Next steps:\n"
    . "1. Arrange a meeting with the seller via UniFind Messages.\n"
    . "2. Meet up and exchange the item.\n"
    . "3. Mark the meeting as completed — your payment will be processed.\n"
    . "4. A payment confirmation email will be sent to you.\n\n"
    . "— UniFind Team";

// ── send email ────────────────────────────────────────────────────────────────

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
    $mail->Subject = "UniFind Invoice — {$itemTitle} (\${$priceFormatted})";
    $mail->Body    = $htmlBody;
    $mail->AltBody = $altBody;
    $mail->send();
    api_success(['message' => 'Invoice sent to ' . $buyerEmail]);
} catch (Exception $e) {
    error_log('Invoice mailer error: ' . ($mail->ErrorInfo ?? $e->getMessage()));
    // Non-fatal — app flow continues even if email fails
    api_success(['message' => 'Payment recorded. Invoice email could not be delivered.']);
}
