<?php

// config.php
// Database connection settings

define('DB_HOST', 'localhost');
define('DB_NAME', 'ivanovs1_UniFind_Test');
define('DB_USER', 'ivanovs1_TestUser');
define('DB_PASS', 'SumayaRahman');

// Message encryption key for AES-256-GCM. Generate once with the browser
// console snippet; losing this means losing all encrypted messages.
define('MESSAGE_KEY', 'Hk/nXWORem0fnPSsDzBCpWBZMqYKp4pG4joiKga7NOU=');

// Create the database connection
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

// Check if connection failed
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $conn->connect_error]);
    exit();
}

// Set character encoding to UTF-8
$conn->set_charset('utf8mb4');

// Shim so the crypto helper (which expects $config['security']['message_key'])
// can find the key without rewriting every caller.
$config = ['security' => ['message_key' => MESSAGE_KEY]];
?>