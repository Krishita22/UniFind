<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/../../config.php';

$body     = json_decode(file_get_contents('php://input'), true);
$username = trim($body['username'] ?? '');
$email    = trim($body['email']    ?? '');

// ── Validate inputs ──────────────────────────────────────────────────────────
if ($username === '') {
    echo json_encode(['success' => false, 'error' => 'Username is required.', 'error_code' => 'MISSING_USERNAME']);
    exit;
}

if ($email === '') {
    echo json_encode(['success' => false, 'error' => 'Email is required.', 'error_code' => 'MISSING_EMAIL']);
    exit;
}

if (strlen($username) < 6) {
    echo json_encode(['success' => false, 'error' => 'Username must be at least 6 characters.', 'error_code' => 'INVALID_USERNAME']);
    exit;
}

if (!preg_match('/^[a-zA-Z0-9_.]+$/', $username)) {
    echo json_encode(['success' => false, 'error' => 'Username contains invalid characters.', 'error_code' => 'INVALID_USERNAME']);
    exit;
}

// ── Check the username isn't already taken ───────────────────────────────────
$check = $conn->prepare("SELECT id FROM users WHERE username = ? LIMIT 1");
$check->bind_param("s", $username);
$check->execute();
$check->store_result();

if ($check->num_rows > 0) {
    echo json_encode(['success' => false, 'error' => 'Username is already taken.', 'error_code' => 'USERNAME_TAKEN']);
    $check->close();
    exit;
}
$check->close();

// ── Update the username ──────────────────────────────────────────────────────
$update = $conn->prepare("UPDATE users SET username = ? WHERE email = ? LIMIT 1");
$update->bind_param("ss", $username, $email);
$update->execute();

if ($update->affected_rows === 0) {
    echo json_encode(['success' => false, 'error' => 'No account found for this email.', 'error_code' => 'USER_NOT_FOUND']);
    $update->close();
    exit;
}

$update->close();
echo json_encode(['success' => true, 'message' => 'Username updated successfully.']);