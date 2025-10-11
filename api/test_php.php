<?php
// Test PHP de base
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

echo json_encode([
    'status' => 'success',
    'message' => 'PHP fonctionne correctement',
    'php_version' => phpversion(),
    'server_time' => date('Y-m-d H:i:s'),
    'server_info' => [
        'HTTP_HOST' => $_SERVER['HTTP_HOST'] ?? 'unknown',
        'SERVER_NAME' => $_SERVER['SERVER_NAME'] ?? 'unknown',
        'REQUEST_URI' => $_SERVER['REQUEST_URI'] ?? 'unknown'
    ]
]);
?>
