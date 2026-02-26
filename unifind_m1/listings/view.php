<?php

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth_guard.php';

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) {
    flash_set('error', 'Invalid listing ID.');
    redirect('index.php');
}

$stmt = db()->prepare('SELECT l.id, l.name, l.description, l.price, l.category, l.image_path, l.created_at, u.full_name, u.email FROM listings l JOIN users u ON u.id = l.user_id WHERE l.id = ? AND l.is_approved = 1 LIMIT 1');
$listing = null;

if ($stmt) {
    $stmt->bind_param('i', $id);
    $stmt->execute();
    $listing = $stmt->get_result()?->fetch_assoc();
    $stmt->close();
}

if (!$listing) {
    flash_set('error', 'Listing not found.');
    redirect('index.php');
}

require_once __DIR__ . '/../includes/header.php';
?>
<article class="card detail-card">
    <img class="detail-image" src="<?= e(base_url($listing['image_path'])) ?>" alt="<?= e($listing['name']) ?>">
    <h1><?= e($listing['name']) ?></h1>
    <p class="price">$<?= e(number_format((float)$listing['price'], 2)) ?></p>
    <p><strong>Category:</strong> <?= e($listing['category']) ?></p>
    <p><?= nl2br(e($listing['description'])) ?></p>
    <p class="meta">Posted by <?= e($listing['full_name']) ?> (<?= e($listing['email']) ?>) on <?= e(date('M j, Y g:i A', strtotime($listing['created_at']))) ?></p>
    <p><a href="<?= e(base_url('index.php')) ?>">Back to listings</a></p>
</article>
<?php require_once __DIR__ . '/../includes/footer.php'; ?>
