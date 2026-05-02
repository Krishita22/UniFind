<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(204);
  exit;
}

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . '/../../config.php';

$input = json_decode(file_get_contents('php://input'), true);

$email      = strtolower(trim($input['email']      ?? ''));
$code       = trim($input['code']                  ?? '');
$firstName  = trim($input['first_name']            ?? '');
$lastName   = trim($input['last_name']             ?? '');
$username   = trim($input['username']              ?? '');
$role       = trim($input['role']                  ?? 'student');
$age        = (int)($input['age']                  ?? 0);
$graduation_year = isset($input['graduation_year']) ? (int)$input['graduation_year'] : null;

// ── Validation ───────────────────────────────────────────────────────────────

if (substr($email, -14) !== '@montclair.edu') {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'Must use @montclair.edu email']);
  exit;
}

if ($code === '') {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'Code is required']);
  exit;
}

if ($firstName === '' || $lastName === '') {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'First and last name are required']);
  exit;
}

if ($username === '') {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'Username is required']);
  exit;
}

if ($age < 16 || $age > 120) {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'A valid age is required']);
  exit;
}

// ── Look up pending verification code ────────────────────────────────────────

$sel = $conn->prepare("
  SELECT id, password_hash, code_hash, expires_at
  FROM email_verification_codes
  WHERE email = ? AND used_at IS NULL
  ORDER BY id DESC
  LIMIT 1
");
$sel->bind_param("s", $email);
$sel->execute();
$row = $sel->get_result()->fetch_assoc();
$sel->close();

if (!$row) {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'No pending verification found']);
  exit;
}

if (strtotime($row['expires_at']) < time()) {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'Verification code expired']);
  exit;
}

if (!hash_equals($row['code_hash'], hash('sha256', $code))) {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'Invalid verification code']);
  exit;
}

// ── Check if email already registered ────────────────────────────────────────

$check = $conn->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
$check->bind_param("s", $email);
$check->execute();
if ($check->get_result()->fetch_assoc()) {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'Email already registered', 'error_code' => 'USER_EXISTS']);
  exit;
}
$check->close();

// ── Check if username already taken ──────────────────────────────────────────

$checkUser = $conn->prepare("SELECT id FROM users WHERE username = ? LIMIT 1");
$checkUser->bind_param("s", $username);
$checkUser->execute();
if ($checkUser->get_result()->fetch_assoc()) {
  http_response_code(400);
  echo json_encode(['success' => false, 'error' => 'Username already taken', 'error_code' => 'USERNAME_TAKEN']);
  exit;
}
$checkUser->close();

// ── Insert new user ───────────────────────────────────────────────────────────

$displayName = $firstName . ' ' . $lastName;

$ins = $conn->prepare("
  INSERT INTO users (email, password_hash, display_name, first_name, last_name, username, role, age, graduation_year)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
");

if (!$ins) {
  http_response_code(500);
  echo json_encode(['success' => false, 'error' => 'Prepare failed: ' . $conn->error]);
  exit;
}

$ins->bind_param("sssssssii",
  $email,
  $row['password_hash'],
  $displayName,
  $firstName,
  $lastName,
  $username,
  $role,
  $age,
  $graduation_year
);

if (!$ins->execute()) {
  http_response_code(500);
  echo json_encode(['success' => false, 'error' => 'Insert failed: ' . $ins->error]);
  exit;
}
$newUserId = $conn->insert_id;
$ins->close();

// ── Mark verification code as used ───────────────────────────────────────────

$upd = $conn->prepare("UPDATE email_verification_codes SET used_at = NOW() WHERE id = ?");
$id  = (int)$row['id'];
$upd->bind_param("i", $id);
$upd->execute();
$upd->close();

echo json_encode([
  'success' => true,
  'message' => 'Account verified and created',
  'user_id' => $newUserId,
  'user' => [
    'id'       => $newUserId,
    'email'    => $email,
    'username' => $username,
    'role'     => $role,
  ]
]);