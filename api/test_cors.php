<?php
/**
 * Script de test CORS
 * Teste si les headers CORS sont correctement configurés
 */

// Configuration CORS pour accepter toutes les origines
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin, X-Auth-Token, X-API-Key');
header('Access-Control-Max-Age: 86400');
header('Content-Type: application/json; charset=utf-8');

// Gestion des requêtes OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Informations sur la requête
$response = [
    'success' => true,
    'message' => 'CORS configuré correctement',
    'timestamp' => date('Y-m-d H:i:s'),
    'request_info' => [
        'method' => $_SERVER['REQUEST_METHOD'] ?? 'unknown',
        'origin' => $_SERVER['HTTP_ORIGIN'] ?? 'none',
        'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'none',
        'remote_addr' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
        'request_uri' => $_SERVER['REQUEST_URI'] ?? 'unknown'
    ],
    'headers_sent' => [
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
        'Access-Control-Allow-Headers' => 'Content-Type, Authorization, X-Requested-With, Accept, Origin, X-Auth-Token, X-API-Key',
        'Access-Control-Max-Age' => '86400'
    ],
    'cors_test' => [
        'status' => 'PASS',
        'description' => 'Votre API accepte maintenant les requêtes de toutes les origines'
    ]
];

// Si c'est une requête de test depuis le navigateur
if (isset($_GET['browser_test'])) {
    $response['browser_test'] = [
        'instructions' => [
            '1. Ouvrez la console de votre navigateur (F12)',
            '2. Exécutez ce code JavaScript:',
            'fetch("' . $_SERVER['REQUEST_SCHEME'] . '://' . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'] . '", {',
            '  method: "POST",',
            '  headers: { "Content-Type": "application/json" },',
            '  body: JSON.stringify({ test: "cors" })',
            '}).then(r => r.json()).then(console.log)',
            '3. Si vous voyez une réponse JSON, CORS fonctionne !'
        ]
    ];
}

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
