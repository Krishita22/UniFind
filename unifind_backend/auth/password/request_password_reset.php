<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
require_once __DIR__ . '/../../config.php';
$input = json_decode(file_get_contents('php://input'), true);
$email = strtolower(trim($input['email'] ?? ''));
if ($email === '' || substr($email, -14) !== '@montclair.edu') {
  echo json_encode([
    'success' => false,
    'error' => 'This is not a verified email.',
    'error_code' => 'EMAIL_NOT_FOUND'
  ]);
  exit;
}
$check = $conn->prepare("SELECT id, first_name FROM users WHERE email = ? LIMIT 1");
$check->bind_param("s", $email);
$check->execute();
$user = $check->get_result()->fetch_assoc();
$check->close();
if (!$user) {
  echo json_encode([
    'success' => false,
    'error' => 'This is not a verified email.',
    'error_code' => 'EMAIL_NOT_FOUND'
  ]);
  exit;
}
$displayName = !empty($user['first_name']) ? $user['first_name'] : 'there';
$code = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
$codeHash = hash('sha256', $code);
$expiresAt = date('Y-m-d H:i:s', time() + 900); // 15 min
$del = $conn->prepare("DELETE FROM password_reset_codes WHERE email = ? AND used_at IS NULL");
$del->bind_param("s", $email);
$del->execute();
$del->close();
$ins = $conn->prepare("INSERT INTO password_reset_codes (email, code_hash, expires_at) VALUES (?, ?, ?)");
$ins->bind_param("sss", $email, $codeHash, $expiresAt);
$ins->execute();
$ins->close();
$subject = "UniFind Password Reset Code";
$body = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>UniFind Password Reset</title>
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
                Hi ' . htmlspecialchars($displayName) . '!
              </p>

              <p style="margin:0 0 20px 0; text-align:center; font-size:16px; line-height:1.6; color:#000000;">
                We received a request to reset your UniFind password. Your reset code expires in 15 minutes:
              </p>

              <p style="color:#000000; font-size:24px; line-height:1.4; margin:20px 0 30px 0; text-align:center; padding:15px; background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px; font-weight:bold;">
                ' . htmlspecialchars($code) . '
              </p>

              <p style="color:#8E8E8E; font-size:13px; line-height:1.6; margin:0 0 40px 0; text-align:center;">
                If you did not request a password reset, you can safely ignore this email.
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
@mail($email, $subject, $body, $headers);
echo json_encode([
  'success' => true,
  'message' => 'Reset code sent.'
]);
exit;