<?php

declare(strict_types=1);

require_once __DIR__ . '/../includes/bootstrap.php';

if (current_user_id() !== null) {
    redirect('index.php');
}

$errors = [];
$oldEmail = '';
$showResendFor = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verify_csrf_or_fail('login_form');

    $email = strtolower(trim((string)($_POST['email'] ?? '')));
    $password = (string)($_POST['password'] ?? '');
    $oldEmail = $email;

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $errors[] = 'Enter a valid email address.';
    }
    if ($password === '') {
        $errors[] = 'Password is required.';
    }

    if (!$errors) {
        $stmt = db()->prepare('SELECT id, full_name, email, password_hash, is_verified FROM users WHERE email = ? LIMIT 1');
        if (!$stmt) {
            $errors[] = 'Server error. Please try again later.';
        } else {
            $stmt->bind_param('s', $email);
            $stmt->execute();
            $user = $stmt->get_result()?->fetch_assoc();
            $stmt->close();

            if (!$user || !password_verify($password, $user['password_hash'])) {
                $errors[] = 'Invalid email or password.';
            } elseif ((int)$user['is_verified'] !== 1) {
                $errors[] = 'Please verify your email before logging in.';
                $showResendFor = $email;
            } else {
                session_regenerate_id(true);
                $_SESSION['user_id'] = (int)$user['id'];
                $_SESSION['email'] = $user['email'];
                $_SESSION['full_name'] = $user['full_name'];
                $_SESSION['logged_in'] = true;
                $_SESSION['is_verified'] = 1;

                flash_set('success', 'Welcome back, ' . $user['full_name'] . '.');
                redirect('index.php');
            }
        }
    }
}

require_once __DIR__ . '/../includes/header.php';
?>
<section class="card auth-card">
    <h1>Login</h1>

    <?php foreach ($errors as $error): ?>
        <div class="flash flash-error"><?= e($error) ?></div>
    <?php endforeach; ?>

    <form method="post" novalidate>
        <?= csrf_input('login_form') ?>

        <label for="email">Email</label>
        <input id="email" name="email" type="email" value="<?= e($oldEmail) ?>" required>

        <label for="password">Password</label>
        <input id="password" name="password" type="password" required>

        <button type="submit">Login</button>
    </form>

    <?php if ($showResendFor !== ''): ?>
        <form method="post" action="<?= e(base_url('auth/resend_verification.php')) ?>" class="inline-form">
            <?= csrf_input('resend_form') ?>
            <input type="hidden" name="email" value="<?= e($showResendFor) ?>">
            <button type="submit" class="link-btn">Resend verification email</button>
        </form>
    <?php endif; ?>

    <p class="muted">Need an account? <a href="<?= e(base_url('auth/register.php')) ?>">Register</a></p>
</section>
<?php require_once __DIR__ . '/../includes/footer.php'; ?>
