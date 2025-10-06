<?php
echo "=== DEBUG AVIS RECHERCHE API ===\n\n";

$testData = [
    'cible_type' => 'particuliers',
    'cible_id' => 1,
    'motif' => 'Test motif de recherche',
    'niveau' => 'moyen',
    'created_by' => 'agent_test',
    'username' => 'agent_test'
];

$url = 'http://localhost:8000/api/routes/index.php?route=/avis-recherche/create';

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

echo "Réponse brute:\n";
echo $result . "\n\n";

if ($result !== false) {
    $data = json_decode($result, true);
    echo "Données décodées:\n";
    var_dump($data);
} else {
    echo "❌ Aucune réponse reçue\n";
}

echo "\n=== FIN DEBUG ===\n";
?>
