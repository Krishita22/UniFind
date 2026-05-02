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
if ($userId <= 0 || $email === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields']);
    exit();
}
$chk = $conn->prepare("SELECT id, username, first_name, has_warning, is_banned FROM users WHERE id = ? LIMIT 1");
$chk->bind_param('i', $userId);
$chk->execute();
$user = $chk->get_result()->fetch_assoc();
$chk->close();
if (!$user) {
    http_response_code(404);
    echo json_encode(['success' => false, 'error' => 'User not found']);
    exit();
}
if ($user['is_banned']) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'User is already banned']);
    exit();
}
if ($user['has_warning']) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'User has already been warned']);
    exit();
}
$upd = $conn->prepare("UPDATE users SET has_warning = 1, warned_at = NOW() WHERE id = ?");
$upd->bind_param('i', $userId);
$ok = $upd->execute();
$upd->close();
if ($ok) {
    $log = $conn->prepare("INSERT INTO user_warnings (user_id) VALUES (?)");
    $log->bind_param('i', $userId);
    $log->execute();
    $log->close();
    $desc = "Warning issued to @{$user['username']} ($email)";
    $alog = $conn->prepare("INSERT INTO admin_activity_log (description, type) VALUES (?, 'user')");
    $alog->bind_param('s', $desc);
    $alog->execute();
    $alog->close();
    $displayName = !empty($user['first_name']) ? $user['first_name'] : 'there';
    $subject = "UniFind Account Warning";
    $emailBody = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>UniFind Account Warning</title>
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
                Your UniFind account has received an official warning from the admin team.
              </p>
              <p style="color:#000000; font-size:15px; line-height:1.6; margin:20px 0 30px 0; text-align:center; padding:15px; background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px;">
                This is a one-time warning. Any further violations of our community guidelines may result in your account being permanently banned and your email being blocked from re-registering.
              </p>
              <p style="color:#8E8E8E; font-size:13px; line-height:1.6; margin:0 0 40px 0; text-align:center;">
                If you believe this warning was issued in error, please contact the UniFind team.
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
echo json_encode(['success' => (bool)$ok]);
?>