<?php

declare(strict_types=1);

use PHPMailer\PHPMailer\Exception;
use PHPMailer\PHPMailer\PHPMailer;

require_once __DIR__ . '/bootstrap.php';

$autoloadPath = __DIR__ . '/../vendor/autoload.php';
if (file_exists($autoloadPath)) {
    require_once $autoloadPath;
} else {
    // Optional fallback for manual PHPMailer upload.
    require_once __DIR__ . '/../vendor/phpmailer/src/Exception.php';
    require_once __DIR__ . '/../vendor/phpmailer/src/PHPMailer.php';
    require_once __DIR__ . '/../vendor/phpmailer/src/SMTP.php';
}

function send_verification_email(string $toEmail, string $toName, string $rawToken): bool
{
    global $config;

    $mail = new PHPMailer(true);

    try {
        $mail->isSMTP();
        $mail->Host = $config['mail']['smtp_host'];
        $mail->SMTPAuth = true;
        $mail->Username = $config['mail']['smtp_user'];
        $mail->Password = $config['mail']['smtp_pass'];
        $mail->Port = (int)$config['mail']['smtp_port'];
        $mail->SMTPSecure = $config['mail']['smtp_secure'];

        $mail->setFrom($config['mail']['from_email'], $config['mail']['from_name']);
        $mail->addAddress($toEmail, $toName);

        $verifyUrl = base_url('auth/verify.php')
            . '?token=' . urlencode($rawToken)
            . '&email=' . urlencode($toEmail);

        $mail->isHTML(true);
        $mail->Subject = 'Verify your UniFind account';
        $mail->Body = '<p>Hello ' . e($toName) . ',</p>'
            . '<p>Click the link below to verify your UniFind account:</p>'
            . '<p><a href="' . e($verifyUrl) . '">Verify Email</a></p>'
            . '<p>This link expires in 24 hours.</p>';
        $mail->AltBody = "Hello {$toName},\n\nVerify your UniFind account: {$verifyUrl}\n\nThis link expires in 24 hours.";

        return $mail->send();
    } catch (Exception $e) {
        error_log('Mailer error: ' . $mail->ErrorInfo);
        return false;
    }
}

function create_verification_token(int $userId): array
{
    global $config;

    $rawToken = bin2hex(random_bytes(32));
    $tokenHash = hash('sha256', $rawToken);
    $ttlHours = (int)($config['security']['verification_token_ttl_hours'] ?? 24);

    $stmt = db()->prepare('INSERT INTO email_verification_tokens (user_id, token_hash, expires_at, created_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? HOUR), NOW())');
    if (!$stmt) {
        throw new RuntimeException('Token prepare failed.');
    }

    $stmt->bind_param('isi', $userId, $tokenHash, $ttlHours);
    if (!$stmt->execute()) {
        $stmt->close();
        throw new RuntimeException('Token execute failed.');
    }

    $stmt->close();

    return [
        'raw_token' => $rawToken,
        'token_hash' => $tokenHash,
    ];
}

function is_resend_rate_limited(int $userId): bool
{
    global $config;

    $cooldown = (int)($config['security']['resend_cooldown_seconds'] ?? 120);

    $stmt = db()->prepare('SELECT created_at FROM email_verification_tokens WHERE user_id = ? ORDER BY id DESC LIMIT 1');
    if (!$stmt) {
        return true;
    }

    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result ? $result->fetch_assoc() : null;
    $stmt->close();

    if (!$row) {
        return false;
    }

    $last = strtotime((string)$row['created_at']);
    if ($last === false) {
        return false;
    }

    return (time() - $last) < $cooldown;
}
