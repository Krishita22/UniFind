<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(204);
  exit;
}

require_once __DIR__ . '/../../config.php';

$input = json_decode(file_get_contents('php://input'), true);
$email = strtolower(trim($input['email'] ?? ''));
$password = $input['password'] ?? '';
$firstName = trim($input['first_name'] ?? '');
$displayName = $firstName !== '' ? $firstName : 'there';

if (substr($email, -14) !== '@montclair.edu') {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'Must use @montclair.edu email']);
  exit;
}

if (strlen($password) < 8) {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'Password must be at least 8 characters']);
  exit;
}

// Check if email exists
$check = $conn->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
$check->bind_param("s", $email);
$check->execute();
if ($check->get_result()->fetch_assoc()) {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'Email already registered']);
  exit;
}
$check->close();

// Check blacklist
$blCheck = $conn->prepare("SELECT id FROM email_blacklist WHERE email = ? LIMIT 1");
$blCheck->bind_param("s", $email);
$blCheck->execute();
if ($blCheck->get_result()->fetch_assoc()) {
  http_response_code(403);
  echo json_encode([
    'success' => false,
    'error' => 'This email is not permitted to register.',
    'error_code' => 'EMAIL_BLACKLISTED'
  ]);
  exit;
}
$blCheck->close();

// Generate verification code
$code = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
$codeHash = hash('sha256', $code);
$passwordHash = password_hash($password, PASSWORD_DEFAULT);
$expiresAt = date('Y-m-d H:i:s', time() + 600);

$del = $conn->prepare("DELETE FROM email_verification_codes WHERE email = ? AND used_at IS NULL");
$del->bind_param("s", $email);
$del->execute();
$del->close();

$ins = $conn->prepare("INSERT INTO email_verification_codes (email, password_hash, code_hash, expires_at) VALUES (?, ?, ?, ?)");
$ins->bind_param("ssss", $email, $passwordHash, $codeHash, $expiresAt);
if (!$ins->execute()) {
  http_response_code(500);
  echo json_encode(['success' => false, 'error' => 'Failed to save verification code']);
  exit;
}
$ins->close();

$subject = "Welcome to UniFind - Verify Your Student Email";
$body = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>UniFind Verification Code</title>
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
                Thank you for joining UniFind! Your verification code expires in 10 minutes:
              </p>

              <p style="color:#000000; font-size:24px; line-height:1.4; margin:20px 0 30px 0; text-align:center; padding:15px; background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px; font-weight:bold;">
                ' . htmlspecialchars($code) . '
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

$sent = @mail($email, $subject, $body, $headers);

if (!$sent) {
  echo json_encode([
    'success' => true,
    'message' => 'Mail failed on server; using debug code fallback',
    'debug_code' => $code
  ]);
  exit;
}

echo json_encode(['success' => true, 'message' => 'Verification code sent']);
exit;