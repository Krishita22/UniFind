<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth_guard.php';
require_once __DIR__ . '/includes/header.php';

$stmt = db()->prepare('SELECT l.id, l.name, l.description, l.price, l.category, l.image_path, l.created_at, u.full_name FROM listings l JOIN users u ON u.id = l.user_id WHERE l.is_approved = 1 ORDER BY l.created_at DESC');
$listings = [];

if ($stmt) {
    $stmt->execute();
    $result = $stmt->get_result();
    while ($row = $result?->fetch_assoc()) {
        $listings[] = $row;
    }
    $stmt->close();
}
?>
<section>
    <div class="page-head">
        <h1>Approved Listings</h1>
        <a class="btn" href="<?= e(base_url('listings/create.php')) ?>">Post a Listing</a>
    </div>

    <?php if (!$listings): ?>
        <div class="card"><p>No listings yet. Be the first to post one.</p></div>
    <?php else: ?>
        <div class="grid">
            <?php foreach ($listings as $listing): ?>
                <article class="listing-card">
                    <a href="<?= e(base_url('listings/view.php?id=' . (int)$listing['id'])) ?>">
                        <img src="<?= e(base_url($listing['image_path'])) ?>" alt="<?= e($listing['name']) ?>">
                    </a>
                    <div class="listing-body">
                        <h2><a href="<?= e(base_url('listings/view.php?id=' . (int)$listing['id'])) ?>"><?= e($listing['name']) ?></a></h2>
                        <p class="price">$<?= e(number_format((float)$listing['price'], 2)) ?></p>
                        <p><strong>Category:</strong> <?= e($listing['category']) ?></p>
                        <p><?= e(short_desc($listing['description'])) ?></p>
                        <p class="meta">Posted by <?= e($listing['full_name']) ?> on <?= e(date('M j, Y', strtotime($listing['created_at']))) ?></p>
                    </div>
                </article>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
</section>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
