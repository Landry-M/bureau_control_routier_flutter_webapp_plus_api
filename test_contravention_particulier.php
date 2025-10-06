<?php
echo "=== TEST CRÉATION CONTRAVENTION POUR PARTICULIER ===\n\n";

// Données de test pour une contravention
$testData = [
    'dossier_id' => '1', // ID d'un particulier existant
    'type_dossier' => 'particulier',
    'date_infraction' => '2025-01-15T14:30:00.000Z',
    'lieu' => 'Avenue de la Paix, Kinshasa',
    'type_infraction' => 'Excès de vitesse',
    'description' => 'Dépassement de la limite de vitesse autorisée de 20 km/h',
    'reference_loi' => 'Art. 15 Code de la route',
    'amende' => '50000',
    'payed' => 'non',
    'username' => 'test_agent'
];

echo "1. Test de création de contravention pour particulier...\n";
echo "Données envoyées:\n";
foreach ($testData as $key => $value) {
    echo "  - $key: $value\n";
}

// Simulation d'appel API
$url = 'http://localhost:8000/api/routes/index.php/contravention/create';

// Préparer les données POST
$postData = http_build_query($testData);

// Configuration du contexte
$context = stream_context_create([
    'http' => [
        'method' => 'POST',
        'header' => 'Content-Type: application/x-www-form-urlencoded',
        'content' => $postData
    ]
]);

$result = @file_get_contents($url, false, $context);

if ($result === false) {
    echo "❌ Erreur lors de l'appel API\n";
    echo "Vérifiez que le serveur est démarré sur localhost:8000\n";
} else {
    $data = json_decode($result, true);
    if ($data && $data['success']) {
        echo "✅ Contravention créée avec succès !\n";
        echo "ID de la contravention: " . ($data['contravention_id'] ?? 'N/A') . "\n";
        if (isset($data['pdf_path'])) {
            echo "PDF généré: " . $data['pdf_path'] . "\n";
        }
    } else {
        echo "❌ Erreur lors de la création: " . ($data['message'] ?? 'Inconnue') . "\n";
        if (isset($data['details'])) {
            echo "Détails: " . print_r($data['details'], true) . "\n";
        }
    }
}

echo "\n2. Vérification de l'endpoint /contravention/create...\n";
$testUrl = 'http://localhost:8000/api/routes/index.php/contravention/create';
$headers = @get_headers($testUrl);
if ($headers && strpos($headers[0], '200') !== false) {
    echo "✅ Endpoint accessible\n";
} else {
    echo "❌ Endpoint non accessible ou erreur\n";
    if ($headers) {
        echo "Status: " . $headers[0] . "\n";
    }
}

echo "\n=== FIN DU TEST ===\n";
?>
