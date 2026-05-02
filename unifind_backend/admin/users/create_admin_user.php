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

$body      = json_decode(file_get_contents('php://input'), true) ?: [];
$firstName = trim($body['first_name'] ?? '');
$lastName  = trim($body['last_name']  ?? '');
$username  = trim($body['username']   ?? '');
$email     = strtolower(trim($body['email'] ?? ''));

if (!$firstName || !$lastName || !$username || !$email) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'All fields are required.', 'error_code' => 'MISSING_FIELDS']);
    exit();
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Invalid email address.', 'error_code' => 'INVALID_EMAIL']);
    exit();
}

// Check for duplicate email
$chkEmail = $conn->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
$chkEmail->bind_param('s', $email);
$chkEmail->execute();
$chkEmail->store_result();
if ($chkEmail->num_rows > 0) {
    $chkEmail->close();
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'An account with this email already exists.', 'error_code' => 'EMAIL_TAKEN']);
    exit();
}
$chkEmail->close();

// Check for duplicate username
$chkUser = $conn->prepare("SELECT id FROM users WHERE username = ? LIMIT 1");
$chkUser->bind_param('s', $username);
$chkUser->execute();
$chkUser->store_result();
if ($chkUser->num_rows > 0) {
    $chkUser->close();
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'That username is already taken.', 'error_code' => 'USERNAME_TAKEN']);
    exit();
}
$chkUser->close();

// Generate a random temporary password (not shown to user)
$chars    = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%';
$password = '';
for ($i = 0; $i < 12; $i++) {
    $password .= $chars[random_int(0, strlen($chars) - 1)];
}

$hashedPassword = password_hash($password, PASSWORD_BCRYPT);
$displayName    = $firstName . ' ' . $lastName;
$role           = 'admin';
$age            = 0;

$stmt = $conn->prepare("
    INSERT INTO users (first_name, last_name, username, display_name, email, password_hash, role, age, is_active, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, NOW())
");
$stmt->bind_param('sssssssi', $firstName, $lastName, $username, $displayName, $email, $hashedPassword, $role, $age);
$ok = $stmt->execute();
$newUserId = $conn->insert_id;
$stmt->close();

if (!$ok) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Failed to create account.']);
    exit();
}

// Log to admin activity
$desc = "Admin account created for @{$username} ({$email})";
$alog = $conn->prepare("INSERT INTO admin_activity_log (description, type) VALUES (?, 'user')");
$alog->bind_param('s', $desc);
$alog->execute();
$alog->close();

$subject   = 'Your UniFind Admin Account';
$emailBody = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Your UniFind Admin Account</title>
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
                Hi ' . htmlspecialchars($firstName) . ',
              </p>
              <p style="margin:0 0 24px 0; text-align:center; font-size:16px; line-height:1.6; color:#000000;">
                An admin account has been created for you on UniFind.
              </p>
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F9F7F4; border-radius:6px; margin:0 0 24px 0;">
                <tr>
                  <td style="padding:16px 20px 8px 20px;">
                    <p style="margin:0; font-size:13px; color:#8E8E8E; text-transform:uppercase; letter-spacing:0.5px;">Username</p>
                    <p style="margin:6px 0 0 0; font-size:20px; font-weight:bold; color:#000000;">' . htmlspecialchars($username) . '</p>
                  </td>
                </tr>
                <tr>
                  <td style="padding:8px 20px 16px 20px;">
                    <p style="margin:0; font-size:13px; color:#8E8E8E; text-transform:uppercase; letter-spacing:0.5px;">Email</p>
                    <p style="margin:6px 0 0 0; font-size:20px; font-weight:bold; color:#000000;">' . htmlspecialchars($email) . '</p>
                  </td>
                </tr>
              </table>
              <p style="color:#444444; font-size:14px; line-height:1.7; margin:0 0 8px 0; text-align:center;">
                To set your password, open UniFind and use <strong>Forgot Password</strong> on the login screen.
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

$conn->close();
echo json_encode(['success' => true, 'user_id' => $newUserId]);
?>