<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once __DIR__ . '/../../config.php';

$input = json_decode(file_get_contents('php://input'), true);
$email = strtolower(trim($input['email'] ?? ''));
$code = trim($input['code'] ?? '');
$newPassword = $input['new_password'] ?? '';

if (substr($email, -14) !== '@montclair.edu') {
  http_response_code(400); echo json_encode(['success'=>false,'error'=>'Invalid email']); exit;
}
if ($code === '' || strlen($newPassword) < 6) {
  http_response_code(400); echo json_encode(['success'=>false,'error'=>'Invalid input']); exit;
}

$sel = $conn->prepare("
  SELECT id, code_hash, expires_at
  FROM password_reset_codes
  WHERE email = ? AND used_at IS NULL
  ORDER BY id DESC
  LIMIT 1
");
$sel->bind_param("s", $email);
$sel->execute();
$row = $sel->get_result()->fetch_assoc();
$sel->close();

if (!$row || strtotime($row['expires_at']) < time() || !hash_equals($row['code_hash'], hash('sha256', $code))) {
  http_response_code(400); echo json_encode(['success'=>false,'error'=>'Invalid or expired code']); exit;
}

$newHash = password_hash($newPassword, PASSWORD_DEFAULT);
$updUser = $conn->prepare("UPDATE users SET password_hash = ? WHERE email = ?");
$updUser->bind_param("ss", $newHash, $email);
if (!$updUser->execute()) {
  http_response_code(500); echo json_encode(['success'=>false,'error'=>'Failed to update password']); exit;
}
$updUser->close();

$updCode = $conn->prepare("UPDATE password_reset_codes SET used_at = NOW() WHERE id = ?");
$id = (int)$row['id'];
$updCode->bind_param("i", $id);
$updCode->execute();
$updCode->close();

echo json_encode(['success'=>true,'message'=>'Password reset successful']);
