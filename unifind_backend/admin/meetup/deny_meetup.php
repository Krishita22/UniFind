<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) {
        header('Content-Type: application/json');
        echo json_encode(['success' => true, 'data' => $data]);
        exit;
    }
    function api_error(string $message, int $status = 400) {
        http_response_code($status);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'error' => $message]);
        exit;
    }
    function api_body(): array {
        $raw = file_get_contents('php://input');
        if ($raw === false || $raw === '') return [];
        $decoded = json_decode($raw, true);
        return is_array($decoded) ? $decoded : [];
    }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body = api_body();
$meetupId = (int)($body['meetup_id'] ?? 0);
$reason = (string)($body['reason'] ?? '');

if ($meetupId <= 0) api_error('meetup_id required.', 400);
if (empty($reason)) api_error('reason required.', 400);

$status = 'denied';
$upd = $conn->prepare('UPDATE lost_found_meetups SET status = ?, denial_reason = ? WHERE id = ?');
if (!$upd) api_error('Failed to prepare: ' . $conn->error, 500);
$upd->bind_param('ssi', $status, $reason, $meetupId);
if (!$upd->execute()) api_error('Failed to deny: ' . $upd->error, 500);
$upd->close();

api_success(['meetup_id' => $meetupId, 'status' => 'denied']);
