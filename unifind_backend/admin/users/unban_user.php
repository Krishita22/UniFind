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
$upd = $conn->prepare("UPDATE users SET is_banned = 0, is_active = 1 WHERE id = ?");
$upd->bind_param('i', $userId);
$ok = $upd->execute();
$upd->close();
$bl = $conn->prepare("DELETE FROM email_blacklist WHERE email = ?");
$bl->bind_param('s', $email);
$bl->execute();
$bl->close();
$r = $conn->prepare("SELECT username, first_name FROM users WHERE id = ? LIMIT 1");
$r->bind_param('i', $userId);
$r->execute();
$row = $r->get_result()->fetch_assoc();
$r->close();
$username  = $row['username']   ?? '';
$firstName = $row['first_name'] ?? '';
$desc = "User unbanned: @$username ($email)";
$alog = $conn->prepare("INSERT INTO admin_activity_log (description, type) VALUES (?, 'user')");
$alog->bind_param('s', $desc);
$alog->execute();
$alog->close();
if ($ok && $email !== '') {
    $displayName = $firstName !== '' ? $firstName : 'there';
    $subject = "Your UniFind Account Has Been Reinstated";
    $emailBody = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>UniFind Account Reinstated</title>
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
                Your UniFind account ban has been reviewed and lifted by the admin team.
              </p>
              <p style="color:#000000; font-size:15px; line-height:1.6; margin:20px 0 30px 0; text-align:center; padding:15px; background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px;">
                You can now log back in and use UniFind. Please ensure your activity on the platform follows our community guidelines going forward.
              </p>
              <p style="color:#8E8E8E; font-size:13px; line-height:1.6; margin:0 0 40px 0; text-align:center;">
                If you have any questions, feel free to contact the UniFind team.
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