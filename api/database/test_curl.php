<?php
/**
 * Test de l'endpoint /auth/login avec cURL
 */

echo "=== TEST CURL DE L'ENDPOINT /auth/login ===\n\n";

// Données de test
$testData = [
    'matricule' => 'boom',
    'password' => 'boombeach'
];

echo "Données envoyées: " . json_encode($testData) . "\n\n";

// URL de l'API (ajustez selon votre configuration)
$apiUrl = 'http://localhost/api/routes/index.php?route=/auth/login';

// Alternative si vous utilisez un serveur local différent
$alternativeUrls = [
    'http://localhost:8000/api/routes/index.php?route=/auth/login',
    'http://127.0.0.1/api/routes/index.php?route=/auth/login',
    'http://localhost/bcr/api/routes/index.php?route=/auth/login'
];

function testUrl($url, $data) {
    $ch = curl_init();
    
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Content-Length: ' . strlen(json_encode($data))
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    
    curl_close($ch);
    
    return [
        'response' => $response,
        'http_code' => $httpCode,
        'error' => $error
    ];
}

// Tester l'URL principale
echo "Test de: $apiUrl\n";
$result = testUrl($apiUrl, $testData);

if ($result['error']) {
    echo "❌ Erreur cURL: {$result['error']}\n";
    
    // Tester les URLs alternatives
    echo "\nTest des URLs alternatives...\n";
    foreach ($alternativeUrls as $altUrl) {
        echo "\nTest de: $altUrl\n";
        $altResult = testUrl($altUrl, $testData);
        
        if (!$altResult['error']) {
            echo "✅ Connexion réussie!\n";
            echo "Code HTTP: {$altResult['http_code']}\n";
            echo "Réponse: {$altResult['response']}\n";
            break;
        } else {
            echo "❌ Erreur: {$altResult['error']}\n";
        }
    }
} else {
    echo "✅ Requête envoyée avec succès!\n";
    echo "Code HTTP: {$result['http_code']}\n";
    echo "Réponse: {$result['response']}\n";
    
    // Analyser la réponse JSON
    $jsonResponse = json_decode($result['response'], true);
    if ($jsonResponse) {
        echo "\n=== ANALYSE DE LA RÉPONSE ===\n";
        if (isset($jsonResponse['status']) && $jsonResponse['status'] === 'ok') {
            echo "✅ Authentification réussie!\n";
            echo "Token: " . ($jsonResponse['token'] ?? 'N/A') . "\n";
            echo "Rôle: " . ($jsonResponse['role'] ?? 'N/A') . "\n";
        } else {
            echo "❌ Authentification échouée\n";
            echo "Message: " . ($jsonResponse['message'] ?? 'N/A') . "\n";
        }
    }
}

echo "\n=== RECOMMANDATIONS ===\n";
echo "1. Vérifiez que votre serveur web (Apache/Nginx) fonctionne\n";
echo "2. Vérifiez l'URL exacte de votre API\n";
echo "3. Vérifiez les logs d'erreur du serveur web\n";
echo "4. Testez depuis votre application Flutter avec la même URL\n";
?>
