<?php
/**
 * api_helpers.php
 * ─────────────────────────────────────────────────────────────────────────
 * Shared bootstrap for all JSON API endpoints on the Test API server.
 * Relies on config.php (already in this directory) for the $conn variable.
 * ─────────────────────────────────────────────────────────────────────────
 */

declare(strict_types=1);

// ── CORS + JSON headers ───────────────────────────────────────────────────
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Preflight — just return 200 and stop
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ── Use the existing config.php DB connection ─────────────────────────────
// config.php already lives in this directory and creates $conn (mysqli).
// We just require it so every endpoint file gets $conn for free.
require_once __DIR__ . '/config.php';

// ── Response helpers ──────────────────────────────────────────────────────

/** Send a successful JSON response and exit. */
function api_success(array $payload = []): never
{
    echo json_encode(array_merge(['success' => true], $payload), JSON_UNESCAPED_UNICODE);
    exit;
}

/** Send an error JSON response and exit. */
function api_error(string $message, int $status = 400, string $code = ''): never
{
    http_response_code($status);
    $body = ['success' => false, 'error' => $message];
    if ($code !== '') $body['error_code'] = $code;
    echo json_encode($body, JSON_UNESCAPED_UNICODE);
    exit;
}

/** Decode the JSON request body. Returns [] if body is empty or invalid. */
function api_body(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === '' || $raw === false) return [];
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}
