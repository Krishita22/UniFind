<?php

declare(strict_types=1);

function db(): mysqli
{
    static $conn = null;
    global $config;

    if ($conn instanceof mysqli) {
        return $conn;
    }

    mysqli_report(MYSQLI_REPORT_OFF);
    $conn = @new mysqli(
        $config['db']['host'],
        $config['db']['user'],
        $config['db']['pass'],
        $config['db']['name']
    );

    if ($conn->connect_error) {
        error_log('DB connection failed: ' . $conn->connect_error);
        http_response_code(500);
        exit('Database connection error.');
    }

    $charset = $config['db']['charset'] ?? 'utf8mb4';
    if (!$conn->set_charset($charset)) {
        error_log('Failed to set DB charset: ' . $conn->error);
        http_response_code(500);
        exit('Database configuration error.');
    }

    return $conn;
}
