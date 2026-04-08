<?php
declare(strict_types=1);

require_once __DIR__ . '/config.php';

function api_success($data) {
    header('Content-Type: application/json');
    echo json_encode(['success' => true, 'data' => $data]);
    exit;
}

function api_error(string $message, int $status = 400, string $code = 'ERROR') {
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode(['success' => false, 'error' => $message, 'error_code' => $code]);
    exit;
}

function api_body(): array {
    $raw = file_get_contents('php://input');
    if ($raw === false || $raw === '') return [];
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}
