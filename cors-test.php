<?php
// Test CORS simple
header('Access-Control-Allow-Origin: https://controls.heaventech.net');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

echo json_encode([
    'status' => 'success',
    'message' => 'CORS test réussi',
    'origin' => $_SERVER['HTTP_ORIGIN'] ?? 'none',
    'method' => $_SERVER['REQUEST_METHOD'] ?? 'none',
    'headers' => getallheaders(),
    'timestamp' => date('Y-m-d H:i:s')
]);
?>
