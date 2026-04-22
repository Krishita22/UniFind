<?php
declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once __DIR__ . '/../api_helpers.php';
require_once __DIR__ . '/../includes/mailer.php';

$body = api_body();

$offerId        = trim($body['offer_id']        ?? '');
$buyerEmail     = trim($body['buyer_email']      ?? '');
$buyerName      = trim($body['buyer_name']       ?? 'UniFind User');
$itemTitle      = trim($body['item_title']       ?? '');
$itemPrice      = isset($body['item_price'])  ? (float)$body['item_price']  : 0.0;
$itemCategory   = trim($body['item_category']    ?? '');
$itemCondition  = trim($body['item_condition']   ?? '');
$itemImage      = trim($body['item_image']       ?? '');
$billingAddress = trim($body['billing_address']  ?? '');

if ($buyerEmail === '' || $itemTitle === '' || $itemPrice <= 0) {
    api_error('Missing required fields: buyer_email, item_title, item_price.');
}

$date    = date('F j, Y');
$time    = date('g:i A');
$priceFormatted = number_format($itemPrice, 2);
$imageHtml = $itemImage !== ''
    ? '<img src="' . htmlspecialchars($itemImage) . '" alt="' . htmlspecialchars($itemTitle) . '" style="width:100%;max-width:320px;border-radius:8px;margin-bottom:16px;">'
    : '';

$htmlBody = <<<HTML
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#f9f2f2;font-family:Georgia,serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f9f2f2;padding:32px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #edd8d8;">

        <!-- Header -->
        <tr>
          <td style="background:#8b1a1a;padding:24px 32px;">
            <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:900;letter-spacing:-0.5px;">UniFind</h1>
            <p style="margin:4px 0 0;color:rgba(255,255,255,0.75);font-size:13px;">Payment Invoice</p>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style="padding:28px 32px;">
            <p style="margin:0 0 6px;font-size:15px;color:#1a1010;font-weight:700;">Hi {$buyerName},</p>
            <p style="margin:0 0 24px;font-size:13px;color:#9c7070;line-height:1.7;">
              Thank you for your payment on UniFind. Your payment details have been received and will be processed once the meeting location is marked as completed.
            </p>

            <!-- Item card -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#fcf8f8;border:1px solid #edd8d8;border-radius:12px;margin-bottom:24px;">
              <tr>
                <td style="padding:20px 24px;">
                  {$imageHtml}
                  <p style="margin:0 0 4px;font-size:16px;font-weight:800;color:#1a1010;">{$itemTitle}</p>
                  <p style="margin:0 0 12px;font-size:12px;color:#9c7070;">{$itemCategory} &middot; {$itemCondition}</p>
                  <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                      <td style="font-size:12px;color:#9c7070;font-weight:600;">Amount Due</td>
                      <td align="right" style="font-size:22px;font-weight:900;color:#a12727;">\${$priceFormatted}</td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>

            <!-- Details table -->
            <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
              <tr>
                <td style="padding:8px 0;border-bottom:1px solid #edd8d8;font-size:12px;color:#9c7070;font-weight:600;">Invoice Reference</td>
                <td align="right" style="padding:8px 0;border-bottom:1px solid #edd8d8;font-size:12px;color:#1a1010;font-weight:700;">{$offerId}</td>
              </tr>
              <tr>
                <td style="padding:8px 0;border-bottom:1px solid #edd8d8;font-size:12px;color:#9c7070;font-weight:600;">Date</td>
                <td align="right" style="padding:8px 0;border-bottom:1px solid #edd8d8;font-size:12px;color:#1a1010;font-weight:700;">{$date} at {$time}</td>
              </tr>
              <tr>
                <td style="padding:8px 0;border-bottom:1px solid #edd8d8;font-size:12px;color:#9c7070;font-weight:600;">Billing Address</td>
                <td align="right" style="padding:8px 0;border-bottom:1px solid #edd8d8;font-size:12px;color:#1a1010;font-weight:700;">{$billingAddress}</td>
              </tr>
              <tr>
                <td style="padding:8px 0;font-size:12px;color:#9c7070;font-weight:600;">Status</td>
                <td align="right" style="padding:8px 0;font-size:12px;font-weight:800;color:#d97706;">Pending — awaiting meetup completion</td>
              </tr>
            </table>

            <!-- Next steps -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:10px;margin-bottom:24px;">
              <tr>
                <td style="padding:16px 20px;">
                  <p style="margin:0 0 8px;font-size:13px;font-weight:800;color:#1e40af;">What happens next</p>
                  <ol style="margin:0;padding-left:18px;font-size:12px;color:#1e40af;line-height:2;">
                    <li>Arrange a meeting with the seller via UniFind Messages.</li>
                    <li>Meet up and exchange the item.</li>
                    <li>Mark the meeting as completed — your payment will then be processed.</li>
                    <li>A final payment confirmation will be sent to this email.</li>
                  </ol>
                </td>
              </tr>
            </table>

            <p style="margin:0;font-size:12px;color:#9c7070;line-height:1.7;">
              If you have any questions, please contact us through the UniFind app.
            </p>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style="background:#fcf8f8;border-top:1px solid #edd8d8;padding:16px 32px;text-align:center;">
            <p style="margin:0;font-size:11px;color:#9c7070;">UniFind &mdash; Montclair State University Campus Marketplace</p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>
HTML;

$altBody = "Hi {$buyerName},\n\n"
    . "Your payment details for \"{$itemTitle}\" (\${$priceFormatted}) have been received.\n\n"
    . "Invoice Reference: {$offerId}\n"
    . "Date: {$date} at {$time}\n"
    . "Status: Pending — awaiting meetup completion\n\n"
    . "Next steps:\n"
    . "1. Arrange a meeting with the seller via UniFind Messages.\n"
    . "2. Meet up and exchange the item.\n"
    . "3. Mark the meeting as completed — your payment will then be processed.\n"
    . "4. A final payment confirmation will be sent to this email.\n\n"
    . "— UniFind Team";

$sent = send_payment_invoice_email($buyerEmail, $buyerName, $itemTitle, $priceFormatted, $htmlBody, $altBody);

if ($sent) {
    api_success(['message' => 'Invoice sent to ' . $buyerEmail]);
} else {
    // Still return success so the app flow continues — email failure is non-fatal
    api_success(['message' => 'Payment recorded. Invoice email could not be delivered.']);
}

// ── mailer helper ─────────────────────────────────────────────────────────────

function send_payment_invoice_email(
    string $toEmail,
    string $toName,
    string $itemTitle,
    string $priceFormatted,
    string $htmlBody,
    string $altBody
): bool {
    global $config;

    $mail = new \PHPMailer\PHPMailer\PHPMailer(true);
    try {
        $mail->isSMTP();
        $mail->Host       = $config['mail']['smtp_host'];
        $mail->SMTPAuth   = true;
        $mail->Username   = $config['mail']['smtp_user'];
        $mail->Password   = $config['mail']['smtp_pass'];
        $mail->Port       = (int)$config['mail']['smtp_port'];
        $mail->SMTPSecure = $config['mail']['smtp_secure'];

        $mail->setFrom($config['mail']['from_email'], $config['mail']['from_name']);
        $mail->addAddress($toEmail, $toName);

        $mail->isHTML(true);
        $mail->Subject = "UniFind Invoice — {$itemTitle} (\${$priceFormatted})";
        $mail->Body    = $htmlBody;
        $mail->AltBody = $altBody;

        return $mail->send();
    } catch (\Exception $e) {
        error_log('Payment invoice mailer error: ' . $mail->ErrorInfo);
        return false;
    }
}
