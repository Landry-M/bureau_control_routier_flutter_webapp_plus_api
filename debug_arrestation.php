<?php
echo "=== DEBUG ARRESTATION API ===\n\n";

// Test de l'endpoint de création
echo "1. Test de l'endpoint de création...\n";

$testData = [
    'particulier_id' => 1,
    'motif' => 'Test arrestation',
    'lieu' => 'Test lieu',
    'date_arrestation' => '2025-01-10T15:30:00.000Z',
    'date_sortie_prison' => null,
    'created_by' => 'test_user',
    'username' => 'test_user'
];

$url = 'http://localhost:8000/api/routes/index.php?route=/arrestation/create';

echo "URL: $url\n";
echo "Data: " . json_encode($testData, JSON_PRETTY_PRINT) . "\n\n";

$context = stream_context_create([
    'http' => [
        'method' => 'POST',
        'header' => 'Content-Type: application/json',
        'content' => json_encode($testData)
    ]
]);

$result = @file_get_contents($url, false, $context);

if ($result === false) {
    echo "❌ Erreur lors de l'appel API\n";
    echo "Vérifiez que le serveur est démarré sur localhost:8000\n";
    
    // Test de connectivité de base
    echo "\n2. Test de connectivité de base...\n";
    $baseUrl = 'http://localhost:8000/api/routes/index.php';
    $baseResult = @file_get_contents($baseUrl);
    if ($baseResult === false) {
        echo "❌ Serveur non accessible sur localhost:8000\n";
    } else {
        echo "✅ Serveur accessible\n";
        echo "Réponse: " . substr($baseResult, 0, 200) . "...\n";
    }
} else {
    echo "✅ Réponse reçue:\n";
    echo $result . "\n";
    
    $data = json_decode($result, true);
    if ($data) {
        if (isset($data['success'])) {
            if ($data['success']) {
                echo "✅ Succès: " . ($data['message'] ?? 'Arrestation créée') . "\n";
            } else {
                echo "❌ Échec: " . ($data['message'] ?? 'Erreur inconnue') . "\n";
            }
        } else {
            echo "⚠️ Format de réponse inattendu\n";
        }
    } else {
        echo "❌ Réponse JSON invalide\n";
    }
}

// Test des headers HTTP
echo "\n3. Test des headers HTTP...\n";
$headers = @get_headers($url);
if ($headers) {
    echo "Headers reçus:\n";
    foreach ($headers as $header) {
        echo "  $header\n";
    }
} else {
    echo "❌ Impossible de récupérer les headers\n";
}

echo "\n=== FIN DEBUG ===\n";
?>
