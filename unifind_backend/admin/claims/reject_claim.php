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

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$claimId = (int)($body['claim_id'] ?? 0);
$reason  = (string)($body['reason'] ?? '');

if ($claimId <= 0) api_error('claim_id required.', 400);
if (empty($reason)) api_error('reason required.', 400);

// Get claim details
$claimStmt = $conn->prepare("
    SELECT c.id, c.claimant_id, c.found_item_id,
           u.email as claimant_email, u.username as claimant_username,
           lf.title as item_title
    FROM lost_found_claims c
    JOIN users u ON c.claimant_id = u.id
    JOIN lost_found_items lf ON c.found_item_id = lf.id
    WHERE c.id = ? LIMIT 1
");
if (!$claimStmt) api_error('Prepare error: ' . $conn->error, 500);
$claimStmt->bind_param('i', $claimId);
if (!$claimStmt->execute()) api_error('Execute error: ' . $claimStmt->error, 500);
$claim = $claimStmt->get_result()->fetch_assoc();
$claimStmt->close();

if (!$claim) api_error('Claim not found.', 404);

// Record rejection in claim_approvals
$rejectionStmt = $conn->prepare("
    INSERT INTO claim_approvals (claim_id, status, rejection_reason)
    VALUES (?, 'rejected', ?)
");
if (!$rejectionStmt) api_error('Rejection insert prepare: ' . $conn->error, 500);
$rejectionStmt->bind_param('is', $claimId, $reason);
if (!$rejectionStmt->execute()) api_error('Rejection insert execute: ' . $rejectionStmt->error, 500);
$rejectionStmt->close();

// Update claim status
$updateStmt = $conn->prepare("UPDATE lost_found_claims SET status = 'rejected' WHERE id = ?");
if (!$updateStmt) api_error('Update prepare: ' . $conn->error, 500);
$updateStmt->bind_param('i', $claimId);
if (!$updateStmt->execute()) api_error('Update execute: ' . $updateStmt->error, 500);
$updateStmt->close();

// Send styled HTML email to claimant
$displayName = htmlspecialchars($claim['claimant_username']);
$itemTitle   = htmlspecialchars($claim['item_title']);
$displayReason = htmlspecialchars($reason);

$emailSubject = 'Your Claim Was Not Approved — UniFind';
$emailHtml = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Claim Not Approved</title>
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
                Hi ' . $displayName . '!
              </p>
              <p style="margin:0 0 24px 0; text-align:center; font-size:15px; line-height:1.6; color:#000000;">
                Unfortunately, your claim was not approved at this time.
              </p>

              <!-- Item block -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px; margin-bottom:20px;">
                <tr>
                  <td style="padding:18px 20px;">
                    <p style="margin:0 0 4px 0; font-size:12px; font-weight:bold; color:#8E8E8E; text-transform:uppercase; letter-spacing:0.5px;">Claimed Item</p>
                    <p style="margin:0; font-size:17px; font-weight:bold; color:#000000;">' . $itemTitle . '</p>
                  </td>
                </tr>
              </table>

              <!-- Reason block -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F9F7F4; border-left:4px solid #8E8E8E; border-radius:4px; margin-bottom:24px;">
                <tr>
                  <td style="padding:18px 20px;">
                    <p style="margin:0 0 4px 0; font-size:12px; font-weight:bold; color:#8E8E8E; text-transform:uppercase; letter-spacing:0.5px;">Reason</p>
                    <p style="margin:0; font-size:14px; line-height:1.6; color:#333333;">' . $displayReason . '</p>
                  </td>
                </tr>
              </table>

              <p style="margin:0 0 24px 0; text-align:center; font-size:14px; line-height:1.7; color:#333333;">
                If you believe this is a mistake, you can resubmit your claim or reach out through the UniFind app for more details.
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

$emailHeaders  = "MIME-Version: 1.0\r\n";
$emailHeaders .= "Content-Type: text/html; charset=UTF-8\r\n";
$emailHeaders .= "From: UniFind <unifind@ivanovs1.nodomain>\r\n";

@mail($claim['claimant_email'], $emailSubject, $emailHtml, $emailHeaders);

api_success([
    'claim_id' => $claimId,
    'status'   => 'rejected'
]);
?>