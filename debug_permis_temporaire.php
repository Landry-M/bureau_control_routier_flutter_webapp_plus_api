<?php
echo "=== DEBUG PERMIS TEMPORAIRE API ===\n\n";

$testData = [
    'cible_type' => 'particulier',
    'cible_id' => 1,
    'motif' => 'Test de génération de permis temporaire',
    'date_debut' => '2025-01-10',
    'date_fin' => '2025-02-10',
    'created_by' => 'agent_test',
    'username' => 'agent_test'
];

$url = 'http://localhost:8000/api/routes/index.php?route=/permis-temporaire/create';

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
    
    if (isset($data['success']) && !$data['success']) {
        echo "\n❌ ERREUR DÉTECTÉE: " . ($data['message'] ?? 'Message non spécifié') . "\n";
    }
} else {
    echo "❌ Aucune réponse reçue du serveur\n";
    echo "Vérifiez que le serveur PHP est démarré sur localhost:8000\n";
}

echo "\n=== VÉRIFICATIONS ===\n";

// Vérifier si la table existe
echo "1. Vérification de la table permis_temporaire...\n";
try {
    $pdo = new PDO('mysql:host=localhost;dbname=control_routier', 'root', '');
    $stmt = $pdo->query("DESCRIBE permis_temporaire");
    if ($stmt) {
        echo "✅ Table permis_temporaire existe\n";
        $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
        echo "Colonnes: " . implode(', ', $columns) . "\n";
    }
} catch (Exception $e) {
    echo "❌ Erreur base de données: " . $e->getMessage() . "\n";
}

// Vérifier si le contrôleur existe
echo "\n2. Vérification du contrôleur...\n";
$controllerPath = __DIR__ . '/api/controllers/PermisTemporaireController.php';
if (file_exists($controllerPath)) {
    echo "✅ PermisTemporaireController.php existe\n";
} else {
    echo "❌ PermisTemporaireController.php manquant\n";
}

// Vérifier si BaseController existe
echo "\n3. Vérification de BaseController...\n";
$baseControllerPath = __DIR__ . '/api/controllers/BaseController.php';
if (file_exists($baseControllerPath)) {
    echo "✅ BaseController.php existe\n";
} else {
    echo "❌ BaseController.php manquant\n";
}

echo "\n=== FIN DEBUG ===\n";
?>
