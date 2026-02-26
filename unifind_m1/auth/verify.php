<?php

declare(strict_types=1);

require_once __DIR__ . '/../includes/bootstrap.php';

$email = strtolower(trim((string)($_GET['email'] ?? '')));
$token = trim((string)($_GET['token'] ?? ''));
$message = '';
$canResend = false;

if (!filter_var($email, FILTER_VALIDATE_EMAIL) || $token === '') {
    $message = 'Invalid verification link.';
    $canResend = true;
} else {
    $stmt = db()->prepare('SELECT id, is_verified FROM users WHERE email = ? LIMIT 1');

    if (!$stmt) {
        $message = 'Server error. Please try again later.';
    } else {
        $stmt->bind_param('s', $email);
        $stmt->execute();
        $user = $stmt->get_result()?->fetch_assoc();
        $stmt->close();

        if (!$user) {
            $message = 'Invalid verification link.';
            $canResend = true;
        } elseif ((int)$user['is_verified'] === 1) {
            flash_set('success', 'Your account is already verified. Please log in.');
            redirect('auth/login.php');
        } else {
            $userId = (int)$user['id'];
            $tokenHash = hash('sha256', $token);

            $tokenStmt = db()->prepare('SELECT id, token_hash FROM email_verification_tokens WHERE user_id = ? AND used_at IS NULL AND expires_at > NOW() ORDER BY id DESC');
            if (!$tokenStmt) {
                $message = 'Server error. Please try again later.';
            } else {
                $tokenStmt->bind_param('i', $userId);
                $tokenStmt->execute();
                $result = $tokenStmt->get_result();

                $validTokenId = null;
                while ($row = $result?->fetch_assoc()) {
                    if (hash_equals($row['token_hash'], $tokenHash)) {
                        $validTokenId = (int)$row['id'];
                        break;
                    }
                }

                $tokenStmt->close();

                if ($validTokenId === null) {
                    $message = 'Link expired or invalid. Please resend verification email.';
                    $canResend = true;
                } else {
                    $updateUser = db()->prepare('UPDATE users SET is_verified = 1 WHERE id = ?');
                    $updateToken = db()->prepare('UPDATE email_verification_tokens SET used_at = NOW() WHERE id = ?');

                    if (!$updateUser || !$updateToken) {
                        $message = 'Server error. Please try again later.';
                    } else {
                        $updateUser->bind_param('i', $userId);
                        $updateToken->bind_param('i', $validTokenId);
                        $okUser = $updateUser->execute();
                        $okToken = $updateToken->execute();
                        $updateUser->close();
                        $updateToken->close();

                        if ($okUser && $okToken) {
                            flash_set('success', 'Verified successfully. Please log in.');
                            redirect('auth/login.php');
                        }

                        $message = 'Verification failed. Please try again.';
                    }
                }
            }
        }
    }
}

require_once __DIR__ . '/../includes/header.php';
?>
<section class="card auth-card">
    <h1>Email Verification</h1>
    <div class="flash flash-error"><?= e($message) ?></div>

    <?php if ($canResend): ?>
        <form method="post" action="<?= e(base_url('auth/resend_verification.php')) ?>" novalidate>
            <?= csrf_input('resend_form') ?>
            <label for="email">Montclair Email</label>
            <input id="email" name="email" type="email" value="<?= e($email) ?>" required>
            <button type="submit">Resend Verification Email</button>
        </form>
    <?php endif; ?>
</section>
<?php require_once __DIR__ . '/../includes/footer.php'; ?>
