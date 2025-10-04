<?php
// Script de test pour vérifier l'API des rapports d'activités

// Configuration
$baseUrl = 'http://localhost/bcr/api/routes/index.php';

// Fonction pour faire une requête HTTP
function makeRequest($url, $method = 'GET', $data = null) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HEADER, false);
    
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        }
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'code' => $httpCode,
        'body' => $response,
        'data' => json_decode($response, true)
    ];
}

echo "=== Test de l'API BCR ===\n\n";

// Test 1: Vérifier l'endpoint des logs
echo "1. Test GET /logs\n";
$response = makeRequest($baseUrl . '?route=/logs');
echo "Code HTTP: " . $response['code'] . "\n";
echo "Réponse: " . $response['body'] . "\n\n";

// Test 2: Créer un utilisateur de test
echo "2. Test POST /users/create\n";
$userData = [
    'nom' => 'Agent Test',
    'matricule' => 'TEST001',
    'poste' => 'Contrôleur',
    'role' => 'agent',
    'telephone' => '+243123456789',
    'password' => 'test123'
];
$response = makeRequest($baseUrl . '?route=/users/create', 'POST', $userData);
echo "Code HTTP: " . $response['code'] . "\n";
echo "Réponse: " . $response['body'] . "\n\n";

// Test 3: Tester la connexion
echo "3. Test POST /auth/login\n";
$loginData = [
    'matricule' => 'admin',
    'password' => 'password123'
];
$response = makeRequest($baseUrl . '?route=/auth/login', 'POST', $loginData);
echo "Code HTTP: " . $response['code'] . "\n";
echo "Réponse: " . $response['body'] . "\n\n";

// Test 4: Vérifier les logs après les actions
echo "4. Test GET /logs (après actions)\n";
$response = makeRequest($baseUrl . '?route=/logs&limit=5');
echo "Code HTTP: " . $response['code'] . "\n";
echo "Réponse: " . $response['body'] . "\n\n";

echo "=== Fin des tests ===\n";
?>
