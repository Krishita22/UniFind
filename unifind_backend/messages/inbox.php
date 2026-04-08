<?php
// messages/inbox.php — Conversation list for the logged-in user
declare(strict_types=1);
require_once __DIR__ . '/../includes/auth_guard.php';

$role = current_user_role();
if ($role === 'admin') {
    flash_set('error', 'Admins do not use the messaging system.');
    redirect('index.php');
}

$uid = current_user_id();

// Fetch all conversations for this user, newest activity first
$stmt = db()->prepare(
    'SELECT c.id, c.subject, c.listing_id, c.created_at,
            c.user1_id, c.user2_id,
            u1.full_name AS user1_name,
            u2.full_name AS user2_name,
            (SELECT body    FROM messages WHERE conversation_id = c.id ORDER BY sent_at DESC LIMIT 1) AS last_msg,
            (SELECT sent_at FROM messages WHERE conversation_id = c.id ORDER BY sent_at DESC LIMIT 1) AS last_at,
            (SELECT COUNT(*) FROM messages
             WHERE conversation_id = c.id AND is_read = 0 AND sender_id != ?) AS unread
     FROM conversations c
     JOIN users u1 ON u1.id = c.user1_id
     JOIN users u2 ON u2.id = c.user2_id
     WHERE c.user1_id = ? OR c.user2_id = ?
     ORDER BY last_at DESC'
);
$convs = [];
if ($stmt) {
    $stmt->bind_param('iii', $uid, $uid, $uid);
    $stmt->execute();
    $result = $stmt->get_result();
    while ($row = $result?->fetch_assoc()) $convs[] = $row;
    $stmt->close();
}

require_once __DIR__ . '/../includes/header.php';
?>
<section>
    <div class="page-head">
        <h1>Messages</h1>
    </div>

    <?php if (!$convs): ?>
        <div class="card">
            <p>No conversations yet.</p>
            <p class="muted">
                Conversations open automatically when you click
                <strong>Contact Seller</strong> on a listing.
            </p>
        </div>
    <?php else: ?>
        <div class="conv-list">
            <?php foreach ($convs as $c):
                $otherName = (int)$c['user1_id'] === $uid ? $c['user2_name'] : $c['user1_name'];
                $unread    = (int)$c['unread'];
                $initial   = mb_strtoupper(mb_substr($otherName, 0, 1));
                $timeLabel = '';
                if ($c['last_at']) {
                    $diff = time() - strtotime($c['last_at']);
                    if ($diff < 60)         $timeLabel = 'Just now';
                    elseif ($diff < 3600)   $timeLabel = floor($diff / 60) . 'm ago';
                    elseif ($diff < 86400)  $timeLabel = floor($diff / 3600) . 'h ago';
                    elseif ($diff < 604800) $timeLabel = floor($diff / 86400) . 'd ago';
                    else                    $timeLabel = date('M j', strtotime($c['last_at']));
                }
            ?>
                <a class="conv-item card <?= $unread > 0 ? 'conv-unread' : '' ?>"
                   href="<?= e(base_url('messages/conversation.php?id=' . (int)$c['id'])) ?>">
                    <div class="conv-avatar"><?= e($initial) ?></div>
                    <div class="conv-body">
                        <div class="conv-header">
                            <strong class="conv-other"><?= e($otherName) ?></strong>
                            <?php if ($unread > 0): ?>
                                <span class="msg-badge"><?= $unread ?></span>
                            <?php endif; ?>
                            <span class="conv-time muted"><?= e($timeLabel) ?></span>
                        </div>
                        <div class="conv-subject muted"><?= e($c['subject']) ?></div>
                        <?php if ($c['last_msg']): ?>
                            <div class="conv-preview muted"><?= e(mb_substr($c['last_msg'], 0, 80)) ?></div>
                        <?php endif; ?>
                    </div>
                    <span class="conv-arrow">›</span>
                </a>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
</section>
<?php require_once __DIR__ . '/../includes/footer.php'; ?>
