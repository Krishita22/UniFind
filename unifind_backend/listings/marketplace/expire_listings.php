<?php
require_once __DIR__ . '/../../config.php';

// Find all active listings older than 10 days
$sel = $conn->prepare("
    SELECT m.id, m.title, u.email, u.username
    FROM marketplace_items m
    JOIN users u ON m.seller_id = u.id
    WHERE m.status = 'active' AND m.is_active = 1
    AND m.created_at <= DATE_SUB(NOW(), INTERVAL 14 DAY)
");
$sel->execute();
$res = $sel->get_result();
$expired = [];
while ($row = $res->fetch_assoc()) $expired[] = $row;
$sel->close();

foreach ($expired as $item) {
    // Deactivate the listing
    $upd = $conn->prepare("UPDATE marketplace_items SET is_active = 0, status = 'denied' WHERE id = ?");
    $upd->bind_param('i', $item['id']);
    $upd->execute();
    $upd->close();

    // Log it
    $desc = "Listing expired after 10 days: \"{$item['title']}\" (#{$item['id']})";
    $log = $conn->prepare("INSERT INTO admin_activity_log (description, type) VALUES (?, 'listing')");
    $log->bind_param('s', $desc);
    $log->execute();
    $log->close();

    // Email the seller
    $subject = "Your UniFind listing has expired";
    $message  = "Hi {$item['username']},\n\n";
    $message .= "Your listing \"{$item['title']}\" has been automatically removed after 14 days.\n\n";
    $message .= "If you'd still like to sell this item, please create a new listing on UniFind.\n\n";
    $message .= "- UniFind Team";
    $headers = "From: unifind@ivanovs1.nodomain\r\n";
    @mail($item['email'], $subject, $message, $headers);
}

$conn->close();
echo "Expired " . count($expired) . " listings.";
?>
```

**Then in cPanel, set up a cron job** to run daily. In cPanel → Cron Jobs, add:
```
0 0 * * * php /home/ivanovs1/public_html/UniFind_Test_API/expire_listings.php