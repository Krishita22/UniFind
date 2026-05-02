<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit();
require_once __DIR__ . '/../../config.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit();
}
$body   = json_decode(file_get_contents('php://input'), true) ?: [];
$userId = (int)($body['user_id'] ?? 0);
$email  = trim($body['email'] ?? '');
if ($userId <= 0 && $email === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing user_id or email']);
    exit();
}
if ($email === '' && $userId > 0) {
    $r = $conn->prepare("SELECT email, username FROM users WHERE id = ? LIMIT 1");
    $r->bind_param('i', $userId);
    $r->execute();
    $row = $r->get_result()->fetch_assoc();
    $r->close();
    if ($row) $email = $row['email'];
}
$username  = '';
$firstName = '';
if ($userId <= 0 && $email !== '') {
    $r2 = $conn->prepare("SELECT id, username, first_name FROM users WHERE email = ? LIMIT 1");
    $r2->bind_param('s', $email);
    $r2->execute();
    $row2 = $r2->get_result()->fetch_assoc();
    $r2->close();
    if ($row2) { $userId = (int)$row2['id']; $username = $row2['username']; $firstName = $row2['first_name'] ?? ''; }
} else {
    $r3 = $conn->prepare("SELECT username, first_name FROM users WHERE id = ? LIMIT 1");
    $r3->bind_param('i', $userId);
    $r3->execute();
    $row3 = $r3->get_result()->fetch_assoc();
    $r3->close();
    if ($row3) { $username = $row3['username']; $firstName = $row3['first_name'] ?? ''; }
}
if ($userId > 0) {
    $upd = $conn->prepare("UPDATE users SET is_banned = 1, is_active = 0 WHERE id = ?");
    $upd->bind_param('i', $userId);
    $upd->execute();
    $upd->close();
    $d1 = $conn->prepare("UPDATE marketplace_items SET is_active = 0 WHERE seller_id = ?");
    $d1->bind_param('i', $userId);
    $d1->execute();
    $d1->close();
}
if ($email !== '') {
    $bl = $conn->prepare("INSERT IGNORE INTO email_blacklist (email, reason) VALUES (?, 'banned')");
    $bl->bind_param('s', $email);
    $bl->execute();
    $bl->close();
}
$desc = "User banned: @$username ($email)";
$alog = $conn->prepare("INSERT INTO admin_activity_log (description, type) VALUES (?, 'user')");
$alog->bind_param('s', $desc);
$alog->execute();
$alog->close();
if ($email !== '') {
    $displayName = $firstName !== '' ? $firstName : 'there';
    $subject = "Your UniFind Account Has Been Banned";
    $emailBody = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>UniFind Account Banned</title>
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
                Hi ' . htmlspecialchars($displayName) . ',
              </p>
              <p style="margin:0 0 20px 0; text-align:center; font-size:16px; line-height:1.6; color:#000000;">
                Your UniFind account has been permanently banned due to violations of our community guidelines.
              </p>
              <p style="color:#000000; font-size:15px; line-height:1.6; margin:20px 0 30px 0; text-align:center; padding:15px; background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px;">
                This decision is final. Your email address has been blocked from re-registering.
              </p>
              <p style="color:#8E8E8E; font-size:13px; line-height:1.6; margin:0 0 40px 0; text-align:center;">
                If you believe this was a mistake, please contact the UniFind team.
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
    @mail($email, $subject, $emailBody, $headers);
}
$conn->close();
echo json_encode(['success' => true]);
?>