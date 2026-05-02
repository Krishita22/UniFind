<?php
/**
 * One-time migration: encrypt any plaintext rows in `messages.body`.
 *
 * Run once via cron (see the "Cron Jobs" section of cPanel):
 *
 *     /usr/local/bin/php /home/<user>/public_html/UniFind_API/migrate_encrypt.php \
 *         > /home/<user>/migrate.log 2>&1
 *
 * Idempotent: rows whose body already starts with "v1:" are skipped, so it is
 * safe to run again (e.g. after a partial run or to catch stragglers). Run
 * this AFTER uploading the updated endpoints and crypto.php, and AFTER setting
 * MESSAGE_KEY in config.php.
 *
 * Not CLI-restricted this time because cPanel's scheduled runs via cron are
 * the only realistic way for the target deployment to execute this; the
 * script still self-guards by requiring a valid MESSAGE_KEY to have been
 * defined in config.php.
 */

declare(strict_types=1);
error_reporting(E_ALL);
ini_set('display_errors', '1');

// Load config. The production config.php here doesn't `return` an array —
// it sets up $conn as a side effect via `define()` + `new mysqli()`, and
// populates $config via the shim block at the bottom. So we just require it
// and trust the variables it creates in this scope.
$configPath = __DIR__ . '/config.php';
if (!is_file($configPath)) {
    fwrite(STDERR, "Missing config.php at {$configPath}\n");
    exit(1);
}
require $configPath;

if (!isset($conn) || !($conn instanceof mysqli)) {
    fwrite(STDERR, "config.php did not create a mysqli connection (\$conn).\n");
    exit(1);
}
if (!isset($config['security']['message_key']) || $config['security']['message_key'] === '') {
    fwrite(STDERR, "MESSAGE_KEY is not set in config.php.\n");
    exit(1);
}

require_once __DIR__ . '/crypto.php';

echo "migrate_encrypt: starting at " . date('c') . PHP_EOL;

$countRow = $conn->query("SELECT COUNT(*) AS n FROM messages WHERE body IS NOT NULL AND body NOT LIKE 'v1:%'");
if (!$countRow) {
    fwrite(STDERR, "Count query failed: {$conn->error}\n");
    exit(1);
}
$pending = (int)($countRow->fetch_assoc()['n'] ?? 0);
echo "Rows pending encryption: {$pending}\n";

if ($pending === 0) {
    echo "Nothing to do.\n";
    exit(0);
}

$sel = $conn->prepare("SELECT id, body FROM messages WHERE body IS NOT NULL AND body NOT LIKE 'v1:%' ORDER BY id ASC");
if (!$sel) {
    fwrite(STDERR, "Prepare (select) failed: {$conn->error}\n");
    exit(1);
}
$sel->execute();
$res = $sel->get_result();

$upd = $conn->prepare('UPDATE messages SET body = ? WHERE id = ?');
if (!$upd) {
    fwrite(STDERR, "Prepare (update) failed: {$conn->error}\n");
    exit(1);
}

$encrypted = 0;
$skipped   = 0;
$failed    = 0;

while ($row = $res->fetch_assoc()) {
    $id   = (int)$row['id'];
    $body = $row['body'];

    if (!is_string($body) || $body === '') {
        $skipped++;
        continue;
    }

    try {
        $cipher = encrypt_message_body($body);
    } catch (Throwable $e) {
        fwrite(STDERR, "id={$id}: encrypt failed: {$e->getMessage()}\n");
        $failed++;
        continue;
    }

    $upd->bind_param('si', $cipher, $id);
    if (!$upd->execute()) {
        fwrite(STDERR, "id={$id}: update failed: {$upd->error}\n");
        $failed++;
        continue;
    }

    $encrypted++;
    if ($encrypted % 50 === 0) {
        echo "  progress: {$encrypted} / {$pending}\n";
    }
}

$sel->close();
$upd->close();
$conn->close();

echo "Done. encrypted={$encrypted}, skipped={$skipped}, failed={$failed}\n";
echo "migrate_encrypt: finished at " . date('c') . PHP_EOL;
exit($failed === 0 ? 0 : 2);
