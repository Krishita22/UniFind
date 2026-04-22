<?php

declare(strict_types=1);

/**
 * One-time migration: encrypt any plaintext rows in `messages.body`.
 *
 * Run once from the shell on the server:
 *
 *     php migrate_encrypt.php
 *
 * Idempotent: rows whose body already starts with "v1:" are skipped, so it is
 * safe to run again (e.g. after a partial run or to catch stragglers). Run
 * this AFTER deploying the updated endpoints and AFTER setting
 * security.message_key — otherwise new writes will land plaintext and this
 * script won't know about them until the next run.
 *
 * CLI-only: refuses to run over HTTP so it can't be hit accidentally.
 */

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit("migrate_encrypt.php: CLI only.\n");
}

// -----------------------------------------------------------------------------
// Load config. The repo has two config conventions:
//   - config/config.php            (used by includes/bootstrap.php)
//   - config.php at repo root      (used by the flat messaging endpoints)
// Either file is expected to `return` an array with db + security sections.
// We try the nested one first because that's the canonical template.
// -----------------------------------------------------------------------------
$candidates = [
    __DIR__ . '/config/config.php',
    __DIR__ . '/config.php',
];

$config = null;
$loadedFrom = null;
foreach ($candidates as $path) {
    if (is_file($path)) {
        /** @psalm-suppress UnresolvableInclude */
        $loaded = require $path;
        if (is_array($loaded)) {
            $config = $loaded;
            $loadedFrom = $path;
            break;
        }
    }
}

if (!is_array($config)) {
    fwrite(STDERR, "No usable config found. Tried:\n  - " . implode("\n  - ", $candidates) . "\n");
    exit(1);
}

if (empty($config['security']['message_key'])) {
    fwrite(STDERR, "security.message_key is not set in {$loadedFrom}. Aborting.\n");
    exit(1);
}

echo "Loaded config from {$loadedFrom}\n";

require_once __DIR__ . '/includes/crypto.php';

// -----------------------------------------------------------------------------
// Build a DB connection directly. We deliberately avoid includes/bootstrap.php
// because it calls session_start(), which is meaningless in CLI and can emit
// warnings depending on php.ini.
// -----------------------------------------------------------------------------
$db = $config['db'] ?? [];
mysqli_report(MYSQLI_REPORT_OFF);
$conn = @new mysqli(
    $db['host'] ?? 'localhost',
    $db['user'] ?? '',
    $db['pass'] ?? '',
    $db['name'] ?? ''
);
if ($conn->connect_error) {
    fwrite(STDERR, "DB connection failed: {$conn->connect_error}\n");
    exit(1);
}
if (!$conn->set_charset($db['charset'] ?? 'utf8mb4')) {
    fwrite(STDERR, "Failed to set charset: {$conn->error}\n");
    exit(1);
}

// -----------------------------------------------------------------------------
// Sanity-check first: how many rows actually need encryption?
// We stream the rows rather than loading them all — bodies may be long.
// -----------------------------------------------------------------------------
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
        // Nothing meaningful to encrypt; leave the row alone.
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
    if ($encrypted % 500 === 0) {
        echo "  progress: {$encrypted} / {$pending}\n";
    }
}

$sel->close();
$upd->close();
$conn->close();

echo "Done. encrypted={$encrypted}, skipped={$skipped}, failed={$failed}\n";
exit($failed === 0 ? 0 : 2);
