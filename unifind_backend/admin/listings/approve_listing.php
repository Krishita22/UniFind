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
$title       = trim($body['title']       ?? '');
$description = trim($body['description'] ?? '');
$category    = trim($body['category']    ?? '');
$condition   = trim($body['condition']   ?? 'Good');
$location    = trim($body['location']    ?? '');
$price       = (float)($body['price']    ?? 0);
$notifyUser  = (bool)($body['notify_user'] ?? true);
$userEmail   = trim($body['user_email']  ?? '');
if ($listingId <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Invalid listing ID']);
    exit();
}
// Pull first_name from DB for marketplace listings
$firstName = '';
if (!$isLostFound) {
    $fn = $conn->prepare("
        SELECT u.first_name
        FROM marketplace_items m
        JOIN users u ON u.id = m.seller_id
        WHERE m.id = ?
        LIMIT 1
    ");
    $fn->bind_param('i', $listingId);
    $fn->execute();
    $fnRow = $fn->get_result()->fetch_assoc();
    $fn->close();
    if ($fnRow) $firstName = $fnRow['first_name'] ?? '';
}
if ($isLostFound) {
    $stmt = $conn->prepare("
        UPDATE lost_found_items
        SET status = 'active', title = ?, description = ?, category = ?, location = ?
        WHERE id = ?
    ");
    $stmt->bind_param('ssssi', $title, $description, $category, $location, $listingId);
} else {
    $stmt = $conn->prepare("
        UPDATE marketplace_items
        SET status = 'active', is_active = 1,
            title = ?, description = ?, category = ?, `condition` = ?, location = ?, price = ?
        WHERE id = ?
    ");
    $stmt->bind_param('sssssdi', $title, $description, $category, $condition, $location, $price, $listingId);
}
$ok = $stmt->execute();
$stmt->close();
if ($ok) {
    // Log activity
    $desc = "Listing #$listingId approved: \"$title\"";
    $type = $isLostFound ? 'lostfound' : 'listing';
    $log = $conn->prepare("INSERT INTO admin_activity_log (description, type) VALUES (?, ?)");
    $log->bind_param('ss', $desc, $type);
    $log->execute();
    $log->close();
    // Notify user via email
    if ($notifyUser && $userEmail !== '') {
        $displayName = $firstName !== '' ? $firstName : 'there';
        $subject = "Your UniFind listing has been approved!";
        $emailBody = '
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>UniFind Listing Approved</title>
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
                Great news! Your listing has been reviewed and approved by the UniFind admin team.
              </p>
              <p style="color:#000000; font-size:18px; line-height:1.4; margin:20px 0 30px 0; text-align:center; padding:15px; background-color:#F9F7F4; border-left:4px solid #DD2635; border-radius:4px; font-weight:bold;">
                ' . htmlspecialchars($title) . '
              </p>
              <p style="margin:0 0 20px 0; text-align:center; font-size:16px; line-height:1.6; color:#000000;">
                It is now live on the app for other students to see.
              </p>
              <p style="color:#8E8E8E; font-size:13px; line-height:1.6; margin:0 0 40px 0; text-align:center;">
                Thank you for using UniFind!
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
        @mail($userEmail, $subject, $emailBody, $headers);
    }
}
$conn->close();
echo json_encode(['success' => (bool)$ok]);
?>