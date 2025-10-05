<?php
/**
 * Test de différentes URLs pour trouver la bonne configuration
 */

echo "=== TEST DES URLs POSSIBLES ===\n\n";

// URLs à tester
$testUrls = [
    'http://localhost/api/routes/index.php?route=/auth/login',
    'http://localhost:8000/api/routes/index.php?route=/auth/login',
    'http://127.0.0.1/api/routes/index.php?route=/auth/login',
    'http://localhost/bcr/api/routes/index.php?route=/auth/login',
    'http://localhost:3000/api/routes/index.php?route=/auth/login',
    'http://localhost:8080/api/routes/index.php?route=/auth/login',
];

// Données de test
$testData = [
    'matricule' => 'boom',
    'password' => 'boombeach'
];

$jsonData = json_encode($testData);

function testUrl($url, $data) {
    $ch = curl_init();
    
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Content-Length: ' . strlen($data)
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 3);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    
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

echo "Données de test: $jsonData\n\n";

$workingUrls = [];

foreach ($testUrls as $url) {
    echo "Test: $url\n";
    
    $result = testUrl($url, $jsonData);
    
    if ($result['error']) {
        echo "❌ Erreur cURL: {$result['error']}\n";
    } else {
        echo "✅ Connexion établie - Code HTTP: {$result['http_code']}\n";
        
        if ($result['http_code'] == 200) {
            // Vérifier si c'est du JSON valide
            $jsonResponse = json_decode($result['response'], true);
            if ($jsonResponse && isset($jsonResponse['status'])) {
                if ($jsonResponse['status'] === 'ok') {
                    echo "🎉 SUCCÈS - Authentification réussie!\n";
                    echo "Token: " . ($jsonResponse['token'] ?? 'N/A') . "\n";
                    $workingUrls[] = $url;
                } else {
                    echo "⚠️  Réponse JSON mais échec: {$jsonResponse['message']}\n";
                }
            } else {
                echo "⚠️  Réponse non-JSON: " . substr($result['response'], 0, 100) . "...\n";
            }
        } else {
            echo "⚠️  Code HTTP non-200\n";
        }
    }
    
    echo "----------------------------------------\n";
}

echo "\n=== RÉSULTATS ===\n";

if (!empty($workingUrls)) {
    echo "✅ URLs fonctionnelles trouvées:\n";
    foreach ($workingUrls as $url) {
        echo "- $url\n";
    }
    
    echo "\n=== SOLUTION ===\n";
    echo "Utilisez une de ces URLs dans votre application Flutter:\n";
    $baseUrl = str_replace('?route=/auth/login', '', $workingUrls[0]);
    echo "ApiClient(baseUrl: '$baseUrl')\n";
} else {
    echo "❌ Aucune URL fonctionnelle trouvée.\n";
    echo "\n=== SOLUTIONS POSSIBLES ===\n";
    echo "1. Démarrer un serveur web local:\n";
    echo "   cd /Users/apple/Documents/dev/flutter/bcr\n";
    echo "   php -S localhost:8000\n";
    echo "\n2. Configurer Apache/Nginx pour pointer vers le dossier bcr\n";
    echo "\n3. Utiliser XAMPP/MAMP/WAMP\n";
}

echo "\n=== COMMANDES UTILES ===\n";
echo "# Démarrer un serveur PHP intégré:\n";
echo "cd /Users/apple/Documents/dev/flutter/bcr\n";
echo "php -S localhost:8000\n";
echo "\n# Puis tester avec:\n";
echo "curl -X POST -H 'Content-Type: application/json' \\\n";
echo "  -d '{\"matricule\":\"boom\",\"password\":\"boombeach\"}' \\\n";
echo "  'http://localhost:8000/api/routes/index.php?route=/auth/login'\n";
?>
