<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$data = json_decode(file_get_contents('php://input'), true);

if (empty($data['image'])) {
    http_response_code(400);
    echo json_encode(['error' => 'No image data received.']);
    exit();
}

$imageData = base64_decode($data['image']);
$uniqueName = uniqid('unifind_', true) . '.jpg';
$uploadDir  = __DIR__ . '/uploads/';
$uploadPath = $uploadDir . $uniqueName;

if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);

if (!file_put_contents($uploadPath, $imageData)) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to save image.']);
    exit();
}

$publicUrl = 'http://cyan.csam.montclair.edu/~ivanovs1/UniFind_Test_API/uploads/' . $uniqueName;

echo json_encode(['success' => true, 'url' => $publicUrl]);
?>