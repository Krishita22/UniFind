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

if ($claimId <= 0) api_error('claim_id required.', 400);

// Get claim details and conversation_id
$claimStmt = $conn->prepare("
    SELECT c.id, c.claimant_id, c.found_item_id, c.status,
           u.email as claimant_email, u.username as claimant_username,
           lf.title as item_title, lf.poster_id as finder_id,
           conv.id as conversation_id
    FROM lost_found_claims c
    JOIN users u ON c.claimant_id = u.id
    JOIN lost_found_items lf ON c.found_item_id = lf.id
    LEFT JOIN conversations conv ON conv.listing_id = c.id
    WHERE c.id = ? LIMIT 1
");
if (!$claimStmt) api_error('Prepare error: ' . $conn->error, 500);
$claimStmt->bind_param('i', $claimId);
if (!$claimStmt->execute()) api_error('Execute error: ' . $claimStmt->error, 500);
$claim = $claimStmt->get_result()->fetch_assoc();
$claimStmt->close();

if (!$claim) api_error('Claim not found.', 404);

// Create conversation if it doesn't exist
if (!$claim['conversation_id']) {
    $convId = null;
    $subject = "Claim: " . $claim['item_title'];

    // Check if conversation already exists
    $existConv = $conn->prepare(
        'SELECT id FROM conversations WHERE listing_id = ? AND ((user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)) LIMIT 1'
    );
    if ($existConv) {
        $existConv->bind_param('iiiii', $claimId, $claim['claimant_id'], $claim['finder_id'], $claim['finder_id'], $claim['claimant_id']);
        $existConv->execute();
        $existRow = $existConv->get_result()->fetch_assoc();
        $existConv->close();
        if ($existRow) $convId = (int)$existRow['id'];
    }

    if ($convId === null) {
        $convIns = $conn->prepare(
            'INSERT INTO conversations (listing_id, user1_id, user2_id, subject, created_at) VALUES (?, ?, ?, ?, NOW())'
        );
        if ($convIns) {
            $convIns->bind_param('iiis', $claimId, $claim['claimant_id'], $claim['finder_id'], $subject);
            if ($convIns->execute()) $convId = (int)$convIns->insert_id;
            $convIns->close();
        }

        // Opening message
        if ($convId !== null) {
            $opener = "Your claim for \"" . $claim['item_title'] . "\" has been approved! You can now coordinate meetup details here.";
            $msgIns = $conn->prepare(
                'INSERT INTO messages (conversation_id, sender_id, body, is_read, sent_at) VALUES (?, ?, ?, 0, NOW())'
            );
            if ($msgIns) {
                $msgIns->bind_param('iis', $convId, $claim['claimant_id'], $opener);
                $msgIns->execute();
                $msgIns->close();
            }
        }
    }

    $claim['conversation_id'] = $convId;
}

// Record approval in claim_approvals
$approvalStmt = $conn->prepare("
    INSERT INTO claim_approvals (claim_id, status, approved_at)
    VALUES (?, 'approved', NOW())
");
if (!$approvalStmt) api_error('Approval insert prepare: ' . $conn->error, 500);
$approvalStmt->bind_param('i', $claimId);
if (!$approvalStmt->execute()) api_error('Approval insert execute: ' . $approvalStmt->error, 500);
$approvalStmt->close();

// Update claim status
$updateStmt = $conn->prepare("UPDATE lost_found_claims SET status = 'approved' WHERE id = ?");
if (!$updateStmt) api_error('Update prepare: ' . $conn->error, 500);
$updateStmt->bind_param('i', $claimId);
if (!$updateStmt->execute()) api_error('Update execute: ' . $updateStmt->error, 500);
$updateStmt->close();

// Send styled HTML email to claimant
$displayName = htmlspecialchars($claim['claimant_username']);
$itemTitle   = htmlspecialchars($claim['item_title']);

$emailSubject = 'Your Claim Has Been Approved — UniFind';
$emailHtml = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Claim Approved</title>
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
                Great news — your claim has been approved!
              </p>

              <!-- Item block -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px; margin-bottom:24px;">
                <tr>
                  <td style="padding:18px 20px;">
                    <p style="margin:0 0 4px 0; font-size:12px; font-weight:bold; color:#8E8E8E; text-transform:uppercase; letter-spacing:0.5px;">Approved Item</p>
                    <p style="margin:0; font-size:17px; font-weight:bold; color:#000000;">' . $itemTitle . '</p>
                  </td>
                </tr>
              </table>

              <p style="margin:0 0 24px 0; text-align:center; font-size:14px; line-height:1.7; color:#333333;">
                You can now open the UniFind app to coordinate a meetup time and location with the item finder directly through your messages.
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
    'claim_id'        => $claimId,
    'status'          => 'approved',
    'conversation_id' => $claim['conversation_id']
]);
?>