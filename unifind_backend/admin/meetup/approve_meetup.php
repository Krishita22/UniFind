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

$body     = json_decode(file_get_contents('php://input'), true) ?? [];
$meetupId = (int)($body['meetup_id'] ?? 0);
if ($meetupId <= 0) api_error('meetup_id required.');

// Check if it's a marketplace meetup first
$marketplaceStmt = $conn->prepare('SELECT meetup_id FROM meetups WHERE meetup_id = ? LIMIT 1');
$isMarketplace = false;
if ($marketplaceStmt) {
    $marketplaceStmt->bind_param('i', $meetupId);
    $marketplaceStmt->execute();
    $mRow = $marketplaceStmt->get_result()->fetch_assoc();
    $marketplaceStmt->close();
    $isMarketplace = $mRow !== null;
}

if ($isMarketplace) {
    $status = 'confirmed';
    $upd = $conn->prepare('UPDATE meetups SET status = ? WHERE meetup_id = ?');
    if (!$upd) api_error('Prepare error: ' . $conn->error, 500);
    $upd->bind_param('si', $status, $meetupId);
    if (!$upd->execute()) api_error('Execute error: ' . $upd->error, 500);
    $upd->close();

    api_success(['meetup_id' => $meetupId, 'type' => 'marketplace', 'status' => 'confirmed']);
}

// Try lost & found meetup
$meetup = $conn->prepare("
    SELECT id, match_id, meetup_date, meetup_time, meetup_location, status
    FROM lost_found_meetups WHERE id = ? LIMIT 1
");
if (!$meetup) api_error('Meetup query prepare: ' . $conn->error, 500);
$meetup->bind_param('i', $meetupId);
if (!$meetup->execute()) api_error('Meetup query execute: ' . $meetup->error, 500);
$meetupData = $meetup->get_result()->fetch_assoc();
$meetup->close();

if (!$meetupData) api_error('Meetup not found', 404);

// Get the match details
$match = $conn->prepare("SELECT lost_item_id, matched_found_item_id FROM lost_found_matches WHERE id = ?");
if (!$match) api_error('Match query prepare: ' . $conn->error, 500);
$match->bind_param('i', $meetupData['match_id']);
if (!$match->execute()) api_error('Match query execute: ' . $match->error, 500);
$matchData = $match->get_result()->fetch_assoc();
$match->close();

if (!$matchData) api_error('Match not found', 404);

// Get lost item
$lostItem = $conn->prepare("SELECT title, poster_id FROM lost_found_items WHERE id = ?");
if (!$lostItem) api_error('Lost item prepare: ' . $conn->error, 500);
$lostItem->bind_param('i', $matchData['lost_item_id']);
if (!$lostItem->execute()) api_error('Lost item execute: ' . $lostItem->error, 500);
$lostItemData = $lostItem->get_result()->fetch_assoc();
$lostItem->close();

if (!$lostItemData) api_error('Lost item not found', 404);

// Get found item
$foundItem = $conn->prepare("SELECT title, poster_id FROM lost_found_items WHERE id = ?");
if (!$foundItem) api_error('Found item prepare: ' . $conn->error, 500);
$foundItem->bind_param('i', $matchData['matched_found_item_id']);
if (!$foundItem->execute()) api_error('Found item execute: ' . $foundItem->error, 500);
$foundItemData = $foundItem->get_result()->fetch_assoc();
$foundItem->close();

if (!$foundItemData) api_error('Found item not found', 404);

// Get lost item poster (claimant)
$lostUser = $conn->prepare("SELECT email, username FROM users WHERE id = ?");
if (!$lostUser) api_error('Lost user prepare: ' . $conn->error, 500);
$lostUser->bind_param('i', $lostItemData['poster_id']);
if (!$lostUser->execute()) api_error('Lost user execute: ' . $lostUser->error, 500);
$lostUserData = $lostUser->get_result()->fetch_assoc();
$lostUser->close();

if (!$lostUserData) api_error('Lost user not found', 404);

// Get found item poster (finder)
$foundUser = $conn->prepare("SELECT email, username FROM users WHERE id = ?");
if (!$foundUser) api_error('Found user prepare: ' . $conn->error, 500);
$foundUser->bind_param('i', $foundItemData['poster_id']);
if (!$foundUser->execute()) api_error('Found user execute: ' . $foundUser->error, 500);
$foundUserData = $foundUser->get_result()->fetch_assoc();
$foundUser->close();

if (!$foundUserData) api_error('Found user not found', 404);

// Update meetup status
$status = 'admin_pending';
$upd = $conn->prepare('UPDATE lost_found_meetups SET status = ? WHERE id = ?');
if (!$upd) api_error('Update prepare: ' . $conn->error, 500);
$upd->bind_param('si', $status, $meetupId);
if (!$upd->execute()) api_error('Update execute: ' . $upd->error, 500);
$upd->close();

// Send styled emails to both users
$dateFormatted = date('D, M j, Y', strtotime($meetupData['meetup_date']));
$timeFormatted = date('g:i A',     strtotime($meetupData['meetup_time']));
$location      = htmlspecialchars($meetupData['meetup_location']);
$itemTitle     = htmlspecialchars($lostItemData['title'] . ' & ' . $foundItemData['title']);

$subject = 'Your UniFind Meetup Has Been Approved!';

foreach ([
    ['email' => $lostUserData['email'],  'name' => $lostUserData['username']],
    ['email' => $foundUserData['email'], 'name' => $foundUserData['username']],
] as $recipient) {
    if (empty($recipient['email'])) continue;

    $name = htmlspecialchars($recipient['name'] ?? 'there');

    $emailHtml = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Meetup Approved</title>
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
                Hi ' . $name . '!
              </p>
              <p style="margin:0 0 24px 0; text-align:center; font-size:15px; line-height:1.6; color:#000000;">
                Your meetup has been <strong style="color:#16A34A;">approved</strong> by the UniFind team.
              </p>

              <!-- Item block -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px; margin-bottom:20px;">
                <tr>
                  <td style="padding:18px 20px;">
                    <p style="margin:0 0 4px 0; font-size:12px; font-weight:bold; color:#8E8E8E; text-transform:uppercase; letter-spacing:0.5px;">Item</p>
                    <p style="margin:0; font-size:17px; font-weight:bold; color:#000000;">' . $itemTitle . '</p>
                  </td>
                </tr>
              </table>

              <!-- Meetup details block -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F9F7F4; border-left:4px solid #8E8E8E; border-radius:4px; margin-bottom:24px;">
                <tr>
                  <td style="padding:18px 20px;">
                    <p style="margin:0 0 4px 0; font-size:12px; font-weight:bold; color:#8E8E8E; text-transform:uppercase; letter-spacing:0.5px;">Meetup Details</p>
                    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="font-size:13px; color:#333333; margin-top:8px;">
                      <tr>
                        <td style="padding:4px 0; font-weight:bold; color:#000000; width:30%;">Location</td>
                        <td style="padding:4px 0;">' . $location . '</td>
                      </tr>
                      <tr>
                        <td style="padding:4px 0; font-weight:bold; color:#000000;">Date</td>
                        <td style="padding:4px 0;">' . $dateFormatted . '</td>
                      </tr>
                      <tr>
                        <td style="padding:4px 0; font-weight:bold; color:#000000;">Time</td>
                        <td style="padding:4px 0;">' . $timeFormatted . '</td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>

              <p style="margin:0 0 24px 0; text-align:center; font-size:14px; line-height:1.7; color:#333333;">
                Please be on time and meet at the agreed location. Stay safe!
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

    $headers  = "MIME-Version: 1.0\r\n";
    $headers .= "Content-type: text/html; charset=UTF-8\r\n";
    $headers .= "From: UniFind <unifind@ivanovs1.nodomain>\r\n";
    @mail($recipient['email'], $subject, $emailHtml, $headers);
}

api_success([
    'meetup_id' => $meetupId,
    'type'      => 'lost_found',
    'status'    => 'admin_pending',
]);
?>