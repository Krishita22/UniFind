<?php
// messages/conversation.php — Single conversation thread + send form
declare(strict_types=1);
require_once __DIR__ . '/../includes/auth_guard.php';

$role = current_user_role();
if ($role === 'admin') {
    flash_set('error', 'Admins do not use the messaging system.');
    redirect('index.php');
}

$uid    = current_user_id();
$convId = (int)($_GET['id'] ?? 0);

if ($convId <= 0) {
    flash_set('error', 'Invalid conversation.');
    redirect('messages/inbox.php');
}

// Verify this user belongs to this conversation
$stmt = db()->prepare(
    'SELECT c.id, c.subject, c.listing_id,
            c.user1_id, c.user2_id,
            u1.full_name AS user1_name,
            u2.full_name AS user2_name
     FROM conversations c
     JOIN users u1 ON u1.id = c.user1_id
     JOIN users u2 ON u2.id = c.user2_id
     WHERE c.id = ? AND (c.user1_id = ? OR c.user2_id = ?) LIMIT 1'
);
$conv = null;
if ($stmt) {
    $stmt->bind_param('iii', $convId, $uid, $uid);
    $stmt->execute();
    $conv = $stmt->get_result()?->fetch_assoc();
    $stmt->close();
}
if (!$conv) {
    flash_set('error', 'Conversation not found.');
    redirect('messages/inbox.php');
}

$otherName = (int)$conv['user1_id'] === $uid ? $conv['user2_name'] : $conv['user1_name'];

// Mark all incoming messages as read
$mark = db()->prepare(
    'UPDATE messages SET is_read = 1 WHERE conversation_id = ? AND sender_id != ? AND is_read = 0'
);
if ($mark) { $mark->bind_param('ii', $convId, $uid); $mark->execute(); $mark->close(); }

// Handle send
$sendError = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['send_message'])) {
    verify_csrf_or_fail('msg_send_form');
    $body = trim((string)($_POST['body'] ?? ''));
    if ($body === '') {
        $sendError = 'Message cannot be empty.';
    } elseif (mb_strlen($body) > 3000) {
        $sendError = 'Message is too long (max 3000 characters).';
    } else {
        $ins = db()->prepare(
            'INSERT INTO messages (conversation_id, sender_id, body, sent_at) VALUES (?, ?, ?, NOW())'
        );
        if ($ins) { $ins->bind_param('iis', $convId, $uid, $body); $ins->execute(); $ins->close(); }
        redirect('messages/conversation.php?id=' . $convId);
    }
}

// Load messages
$msgStmt = db()->prepare(
    'SELECT m.id, m.body, m.sent_at, m.sender_id, u.full_name AS sender_name
     FROM messages m JOIN users u ON u.id = m.sender_id
     WHERE m.conversation_id = ?
     ORDER BY m.sent_at ASC'
);
$messages = [];
if ($msgStmt) {
    $msgStmt->bind_param('i', $convId);
    $msgStmt->execute();
    $result = $msgStmt->get_result();
    while ($row = $result?->fetch_assoc()) $messages[] = $row;
    $msgStmt->close();
}

// Context back-link
$backLink  = '';
$backLabel = '';
if ($conv['listing_id']) {
    $backLink  = base_url('listings/view.php?id=' . (int)$conv['listing_id']);
    $backLabel = '← View Listing';
}

require_once __DIR__ . '/../includes/header.php';
?>
<section class="conv-page">
    <div class="conv-page-head">
        <a class="back-link" href="<?= e(base_url('messages/inbox.php')) ?>">← Inbox</a>
        <div class="conv-page-title">
            <h1><?= e($conv['subject']) ?></h1>
            <p class="muted conv-with">Conversation with <strong><?= e($otherName) ?></strong></p>
        </div>
        <?php if ($backLink): ?>
            <a class="btn btn-sm btn-secondary" href="<?= e($backLink) ?>"><?= e($backLabel) ?></a>
        <?php endif; ?>
    </div>

    <?php if ($sendError): ?>
        <div class="flash flash-error"><?= e($sendError) ?></div>
    <?php endif; ?>

    <!-- Message thread -->
    <div class="msg-thread" id="msg-thread">
        <?php if (!$messages): ?>
            <p class="muted msg-empty">No messages yet. Say hello!</p>
        <?php endif; ?>
        <?php foreach ($messages as $msg):
            $isMine = (int)$msg['sender_id'] === $uid;
        ?>
            <div class="msg-bubble <?= $isMine ? 'msg-mine' : 'msg-theirs' ?>">
                <div class="msg-meta">
                    <span class="msg-sender"><?= e($isMine ? 'You' : $otherName) ?></span>
                    <span class="msg-time muted"><?= e(date('M j, g:i A', strtotime($msg['sent_at']))) ?></span>
                </div>
                <div class="msg-body"><?= nl2br(e($msg['body'])) ?></div>
            </div>
        <?php endforeach; ?>
    </div>

    <!-- Compose form -->
    <form class="msg-compose card" method="post">
        <?= csrf_input('msg_send_form') ?>
        <label for="body" class="sr-only">Your message</label>
        <textarea id="body" name="body" rows="3"
                  placeholder="Type your message…"
                  maxlength="3000" required></textarea>
        <div class="compose-footer">
            <span class="muted compose-hint">Ctrl + Enter to send</span>
            <button type="submit" name="send_message" value="1" class="btn">Send</button>
        </div>
    </form>
</section>

<script>
// Auto-scroll to bottom on load
(function () {
    var t = document.getElementById('msg-thread');
    if (t) t.scrollTop = t.scrollHeight;
})();
// Ctrl+Enter to submit
document.getElementById('body')?.addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
        e.preventDefault();
        this.closest('form').submit();
    }
});
</script>
<?php require_once __DIR__ . '/../includes/footer.php'; ?>
