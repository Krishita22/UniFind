<?php
error_reporting(E_ALL);
ini_set('display_errors', '1');
require_once __DIR__ . '/../config.php';
header('Content-Type: text/plain');

echo "=== users columns ===\n";
$r = $conn->query("SHOW COLUMNS FROM users");
if ($r) { while ($row = $r->fetch_assoc()) echo $row['Field'] . " | " . $row['Type'] . " | " . $row['Null'] . "\n"; }
else echo "Error: " . $conn->error . "\n";
