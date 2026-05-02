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
$body        = json_decode(file_get_contents('php://input'), true) ?: [];
$listingId   = (int)($body['listing_id']   ?? 0);
$isLostFound = (bool)($body['is_lost_found'] ?? false);
if ($listingId <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing listing_id']);
    exit();
}
if ($isLostFound) {
    $r = $conn->prepare("
        SELECT l.title, u.email, u.username, u.first_name
        FROM lost_found_items l
        JOIN users u ON l.poster_id = u.id
        WHERE l.id = ? LIMIT 1
    ");
    $r->bind_param('i', $listingId);
    $r->execute();
    $row = $r->get_result()->fetch_assoc();
    $r->close();
    $title     = $row['title']      ?? '';
    $email     = $row['email']      ?? '';
    $username  = $row['username']   ?? '';
    $firstName = $row['first_name'] ?? '';
    $stmt = $conn->prepare("UPDATE lost_found_items SET status = 'denied' WHERE id = ?");
} else {
    $r = $conn->prepare("
        SELECT m.title, u.email, u.username, u.first_name
        FROM marketplace_items m
        JOIN users u ON m.seller_id = u.id
        WHERE m.id = ? LIMIT 1
    ");
    $r->bind_param('i', $listingId);
    $r->execute();
    $row = $r->get_result()->fetch_assoc();
    $r->close();
    $title     = $row['title']      ?? '';
    $email     = $row['email']      ?? '';
    $username  = $row['username']   ?? '';
    $firstName = $row['first_name'] ?? '';
    $stmt = $conn->prepare("UPDATE marketplace_items SET is_active = 0, status = 'denied' WHERE id = ?");
}
$stmt->bind_param('i', $listingId);
$ok = $stmt->execute();
$stmt->close();
if ($ok) {
    $type = $isLostFound ? 'lostfound' : 'listing';
    $desc = "Listing removed by admin: \"$title\" (#$listingId)";
    $alog = $conn->prepare("INSERT INTO admin_activity_log (description, type) VALUES (?, ?)");
    $alog->bind_param('ss', $desc, $type);
    $alog->execute();
    $alog->close();
    if ($email !== '') {
        $displayName = $firstName !== '' ? $firstName : 'there';
        $subject = "Your UniFind Listing Has Been Removed";
        $emailBody = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>UniFind Listing Removed</title>
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
                Your listing <strong>&ldquo;' . htmlspecialchars($title) . '&rdquo;</strong> has been reviewed and removed by the UniFind admin team.
              </p>
              <p style="color:#000000; font-size:15px; line-height:1.6; margin:20px 0 30px 0; text-align:center; padding:15px; background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px;">
                This may be due to inappropriate or prohibited content, misleading or fraudulent information, or personal information included in the listing.
              </p>
              <p style="color:#8E8E8E; font-size:13px; line-height:1.6; margin:0 0 40px 0; text-align:center;">
                If you believe this was a mistake, please contact the UniFind team through your MSU email.
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
}
$conn->close();
echo json_encode(['success' => (bool)$ok]);
?>