<?php
declare(strict_types=1);

// Allow cross-origin requests from the Flutter app
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed.']);
    exit;
}

if (empty($_FILES['file'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'No file received.']);
    exit;
}

$file   = $_FILES['file'];
$maxBytes = 5 * 1024 * 1024; // 5 MB

// Check for PHP-level upload errors first
if ($file['error'] !== UPLOAD_ERR_OK) {
    $phpErrors = [
        UPLOAD_ERR_INI_SIZE   => 'The image is too large (server limit exceeded). Please use an image under 5 MB.',
        UPLOAD_ERR_FORM_SIZE  => 'The image is too large. Please use an image under 5 MB.',
        UPLOAD_ERR_PARTIAL    => 'Upload was interrupted. Please try again.',
        UPLOAD_ERR_NO_FILE    => 'No file was uploaded.',
        UPLOAD_ERR_NO_TMP_DIR => 'Server configuration error. Please contact support.',
        UPLOAD_ERR_CANT_WRITE => 'Server could not save the file. Please contact support.',
        UPLOAD_ERR_EXTENSION  => 'Upload blocked by server extension.',
    ];
    $msg = $phpErrors[$file['error']] ?? 'Upload failed with error code ' . $file['error'] . '.';
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => $msg]);
    exit;
}

// Size check
if ($file['size'] > $maxBytes) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Image is too large (' . round($file['size'] / 1048576, 1) . ' MB). Please use an image under 5 MB.',
    ]);
    exit;
}

// MIME type validation via finfo
$finfo    = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $file['tmp_name']);
finfo_close($finfo);

$allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
if (!in_array($mimeType, $allowed, true)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Unsupported image format. Please upload a JPEG, PNG, WEBP, or GIF file.',
    ]);
    exit;
}

$ext = match ($mimeType) {
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    'image/webp' => 'webp',
    'image/gif'  => 'gif',
    default      => 'jpg',
};

// Save to listings/ subdirectory
$uploadDir = __DIR__ . '/listings/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

$filename = bin2hex(random_bytes(16)) . '.' . $ext;
$destPath = $uploadDir . $filename;

if (!move_uploaded_file($file['tmp_name'], $destPath)) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Failed to save image. Please try again.']);
    exit;
}

// Build a public URL — derive base from server vars
$scheme   = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host     = $_SERVER['HTTP_HOST'] ?? 'localhost';
$dir      = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/');
$publicUrl = "$scheme://$host$dir/listings/$filename";

echo json_encode(['success' => true, 'url' => $publicUrl]);
