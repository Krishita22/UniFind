<?php
// login.php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed. Use POST.']);
    exit();
}


// Get the JSON body sent from Flutter
$data = json_decode(file_get_contents('php://input'), true);

$username = isset($data['email']) ? trim($data['email']) : '';  // Flutter still sends this as 'email' key
$password = isset($data['password']) ? trim($data['password']) : '';

// Making sure both fields were provided
if (empty($username) || empty($password)) {
    http_response_code(400);
    echo json_encode(['error' => 'Username and password are required.']);
    exit();
}

// Look up the user by username
$stmt = $conn->prepare('SELECT id, email, display_name, password_hash, role, username 
    FROM users WHERE BINARY username = ? AND is_active = 1');
$stmt->bind_param('s', $username);
$stmt->execute();
$result = $stmt->get_result();
$user   = $result->fetch_assoc();
$stmt->close();

// Check if user exists
if (!$user) {
    http_response_code(401);
    echo json_encode([
        'success'    => false,
        'error'      => 'No account found for this username.',
        'error_code' => 'USER_NOT_FOUND',
    ]);
    exit();
}

// Check if password matches
if (!password_verify($password, $user['password_hash'])) {
    http_response_code(401);
    echo json_encode([
        'success'    => false,
        'error'      => 'Invalid username or password.',
        'error_code' => 'INVALID_CREDENTIALS',
    ]);
    exit();
}

// Login successful — return user info
echo json_encode([
    'success' => true,
    'user'    => [
        'id'           => $user['id'],
        'email'        => $user['email'],
        'username'     => $user['username'],
        'display_name' => $user['display_name'],
        'role'         => $user['role'], 
    ],
]);

$conn->close();
?>