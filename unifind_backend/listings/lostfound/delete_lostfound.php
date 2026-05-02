<?php
declare(strict_types=1);
require_once __DIR__ . '/../../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data = []) {
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
}

$body  = json_decode(file_get_contents('php://input'), true);
$id    = isset($body['id'])    ? (int)trim((string)$body['id'])  : 0;
$email = isset($body['email']) ? strtolower(trim($body['email'])) : '';

if ($id <= 0)      api_error('Item ID is required.');
if ($email === '') api_error('Email is required.');

// Step 1: find the user by email (users table columns: id, email, ...)
$userStmt = $conn->prepare('SELECT id FROM users WHERE LOWER(email) = ?');
if (!$userStmt) api_error('Server error.', 500);
$userStmt->bind_param('s', $email);
$userStmt->execute();
$userRow = $userStmt->get_result()->fetch_assoc();
$userStmt->close();

if (!$userRow) api_error('User not found.', 403);
$userId = (int)$userRow['id'];

// Step 2: confirm this user is the poster (lost_found_items.poster_id = users.id)
$checkStmt = $conn->prepare(
    'SELECT id FROM lost_found_items WHERE id = ? AND poster_id = ?'
);
if (!$checkStmt) api_error('Server error.', 500);
$checkStmt->bind_param('ii', $id, $userId);
$checkStmt->execute();
$found = $checkStmt->get_result()->num_rows;
$checkStmt->close();

if ($found === 0) {
    api_error('Item not found or you do not have permission to delete it.', 403);
}

// Step 3: delete it
$delStmt = $conn->prepare('DELETE FROM lost_found_items WHERE id = ?');
if (!$delStmt) api_error('Server error.', 500);
$delStmt->bind_param('i', $id);
$delStmt->execute();
$affected = $delStmt->affected_rows;
$delStmt->close();

if ($affected === 0) api_error('Nothing was deleted — item may already be gone.');

api_success(['deleted_id' => $id]);