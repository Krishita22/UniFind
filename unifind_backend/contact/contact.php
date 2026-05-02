<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

require_once __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

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

$input = json_decode(file_get_contents('php://input'), true);

$name    = trim($input['name']    ?? '');
$email   = trim($input['email']   ?? '');
$subject = trim($input['subject'] ?? '');
$message = trim($input['message'] ?? '');

if (!$name || !$email || !$subject || !$message) {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'All fields are required']);
  exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'Invalid email address']);
  exit;
}

$to          = 'vaghanik1@montclair.edu';
$subjectLine = "UniFind Contact: $subject";

$body = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>New UniFind Message</title>
</head>
<body style="margin:0; padding:0; background-color:#F5F2ED; font-family: Helvetica, Arial, sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F5F2ED; padding:40px 20px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:500px; background-color:#FFFFFF; border-radius:8px; box-shadow:0 4px 12px rgba(0,0,0,0.08); overflow:hidden;">
          <tr>
            <td align="center" style="padding:40px 30px;">
             
              <!-- Logo -->
              <img src="https://i.imgur.com/wfe6qox.png" alt="UniFind Logo" style="width:220px; height:auto; margin-bottom:30px;">
              
              <!-- Header -->
                <p style="margin:0 0 20px 0; text-align:center; font-size:20px; line-height:1.2;">
                  <span style="font-family:Arial, Helvetica, sans-serif; font-weight:bold; color:#000000;">
                    You have a new message!
                  </span>
                </p>

              <!-- Body -->
              <p style="color:#000000; font-family: Helvetica, Arial, sans-serif; font-size:16px; line-height:1.6; margin:0 0 20px 0; text-align:left;">
                <strong>' . htmlspecialchars($name) . '</strong> (<a href="mailto:' . htmlspecialchars($email) . '" style="color:#000000; text-decoration:none;">' . htmlspecialchars($email) . '</a>) sent the following message:
              </p>

              <p style="color:#000000; font-family: Helvetica, Arial, sans-serif; font-size:16px; line-height:1.6; margin:0 0 30px 0; text-align:left; padding:15px; background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px;">
                ' . nl2br(htmlspecialchars($message)) . '
              </p>

              <!-- Reply button -->
              <a href="mailto:' . htmlspecialchars($email) . '" style="display:inline-block; padding:12px 24px; background-color:#DD2635; color:#FFFFFF; text-decoration:none; border-radius:4px; font-weight:600; font-family: Inter, Helvetica, Arial, sans-serif;">
                Reply to ' . htmlspecialchars($name) . '
              </a>

              <!-- Footer -->
              <p style="color:#8E8E8E; font-size:12px; line-height:1.4; margin-top:40px; text-align:center;">
                © 2026 UniFind. All rights reserved.
              </p>

            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>';

$headers  = "MIME-Version: 1.0\r\n";
$headers .= "Content-type: text/html; charset=UTF-8\r\n";
$headers .= "From: UniFind <unifind@ivanovs1.nodomain>\r\n";
$headers .= "Reply-To: $email\r\n";

$sent = mail($to, $subjectLine, $body, $headers);

if (!$sent) {
  $error = error_get_last();
  http_response_code(500);
  echo json_encode(['success' => false, 'error' => 'Mail failed', 'debug' => $error]);
  exit;
}

echo json_encode(['success' => true, 'message' => 'Message sent successfully']);
exit;