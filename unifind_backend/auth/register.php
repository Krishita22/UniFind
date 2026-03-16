<?php

declare(strict_types=1);

require_once __DIR__ . '/../includes/bootstrap.php';
require_once __DIR__ . '/../includes/mailer.php';

if (current_user_id() !== null) {
    redirect('index.php');
}

$errors = [];
$old = [
    'full_name' => '',
    'email' => '',
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verify_csrf_or_fail('register_form');

    $fullName = trim((string)($_POST['full_name'] ?? ''));
    $email = strtolower(trim((string)($_POST['email'] ?? '')));
    $password = (string)($_POST['password'] ?? '');
    $confirmPassword = (string)($_POST['confirm_password'] ?? '');

    $old['full_name'] = $fullName;
    $old['email'] = $email;

    if ($fullName === '') {
        $errors[] = 'Full name is required.';
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $errors[] = 'Enter a valid email address.';
    } elseif (!is_montclair_email($email)) {
        $errors[] = 'Only @montclair.edu emails are allowed.';
    }

    if (!is_valid_password($password)) {
        $errors[] = 'Password must be at least 8 characters and include at least one letter and one number.';
    }

    if ($confirmPassword === '' || !hash_equals($password, $confirmPassword)) {
        $errors[] = 'Passwords do not match.';
    }

    if (!$errors) {
        $stmt = db()->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
        if (!$stmt) {
            $errors[] = 'Server error. Please try again later.';
        } else {
            $stmt->bind_param('s', $email);
            $stmt->execute();
            $exists = $stmt->get_result()?->fetch_assoc();
            $stmt->close();

            if ($exists) {
                $errors[] = 'Email is already registered.';
            }
        }
    }

    if (!$errors) {
        $passwordHash = password_hash($password, PASSWORD_DEFAULT);

        $insert = db()->prepare('INSERT INTO users (full_name, email, password_hash, is_verified, created_at) VALUES (?, ?, ?, 0, NOW())');
        if (!$insert) {
            $errors[] = 'Server error. Please try again later.';
        } else {
            $insert->bind_param('sss', $fullName, $email, $passwordHash);

            if (!$insert->execute()) {
                error_log('Register insert failed: ' . $insert->error);
                $errors[] = 'Could not create account right now. Please try again.';
            }

            $userId = (int)$insert->insert_id;
            $insert->close();

            if (!$errors) {
                try {
                    $tokenData = create_verification_token($userId);
                    $sent = send_verification_email($email, $fullName, $tokenData['raw_token']);

                    if (!$sent) {
                        $errors[] = 'Account created, but verification email could not be sent. Please use resend verification.';
                    } else {
                        flash_set('success', 'Check your Montclair email to verify your account.');
                        redirect('auth/login.php');
                    }
                } catch (Throwable $e) {
                    error_log('Verification token/send failed: ' . $e->getMessage());
                    $errors[] = 'Account created, but verification email could not be sent. Please use resend verification.';
                }
            }
        }
    }
}

require_once __DIR__ . '/../includes/header.php';
?>
<section class="card auth-card">
    <h1>Create Account</h1>
    <?php foreach ($errors as $error): ?>
        <div class="flash flash-error"><?= e($error) ?></div>
    <?php endforeach; ?>

    <form method="post" novalidate>
        <?= csrf_input('register_form') ?>

        <label for="full_name">Full Name</label>
        <input id="full_name" name="full_name" type="text" value="<?= e($old['full_name']) ?>" required maxlength="120">

        <label for="email">Montclair Email</label>
        <input id="email" name="email" type="email" value="<?= e($old['email']) ?>" required pattern=".+@montclair\.edu">

        <label for="password">Password</label>
        <input id="password" name="password" type="password" required minlength="8">

        <label for="confirm_password">Confirm Password</label>
        <input id="confirm_password" name="confirm_password" type="password" required minlength="8">

        <button type="submit">Register</button>
    </form>
    <p class="muted">Already have an account? <a href="<?= e(base_url('auth/login.php')) ?>">Login</a></p>
</section>
<?php require_once __DIR__ . '/../includes/footer.php'; ?>
