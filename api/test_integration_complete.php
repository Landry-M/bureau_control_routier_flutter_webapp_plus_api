<?php
/**
 * Test d'intégration complète : Création d'entreprise avec contravention et génération PDF
 */

echo "=== Test d'intégration complète ===\n\n";

// Données de test pour l'entreprise avec contravention
$testData = [
    'route' => '/create-entreprise-with-contravention',
    'nom_entreprise' => 'Test Entreprise SARL',
    'rccm' => 'CD/KIN/RCCM/23-B-12345',
    'adresse' => '123 Avenue Kasa-Vubu, Kinshasa',
    'telephone' => '+243 81 234 5678',
    'email' => 'test@entreprise.cd',
    'type_activite' => 'Commerce général',
    'personne_contact' => 'Jean Mukendi',
    'telephone_contact' => '+243 99 876 5432',
    'notes' => 'Entreprise de test pour validation du système',
    
    // Données de contravention
    'contrav_date_heure' => date('Y-m-d H:i:s'),
    'contrav_lieu' => 'Kinshasa - Rond-point Ngaba',
    'contrav_type_infraction' => 'Stationnement interdit',
    'contrav_reference_loi' => 'Art. 45 Code de la route',
    'contrav_montant' => '25000',
    'contrav_description' => 'Véhicule stationné dans une zone interdite',
    'contrav_payee' => '0'
];

// Simuler une requête POST vers l'endpoint
$url = 'http://localhost:8000/routes/index.php';

// Préparer les données pour l'envoi
$postData = http_build_query($testData);

// Configuration du contexte HTTP
$context = stream_context_create([
    'http' => [
        'method' => 'POST',
        'header' => "Content-Type: application/x-www-form-urlencoded\r\n" .
                   "Content-Length: " . strlen($postData) . "\r\n",
        'content' => $postData
    ]
]);

echo "1. Envoi de la requête vers l'API...\n";
echo "URL: $url\n";
echo "Données: " . json_encode($testData, JSON_PRETTY_PRINT) . "\n\n";

// Faire la requête
$response = @file_get_contents($url, false, $context);

if ($response === false) {
    echo "❌ Erreur: Impossible de contacter l'API\n";
    echo "Vérifiez que le serveur local est démarré sur http://localhost:8000\n";
    exit(1);
}

echo "2. Réponse de l'API:\n";
echo $response . "\n\n";

// Analyser la réponse
$responseData = json_decode($response, true);

if ($responseData && isset($responseData['status']) && $responseData['status'] === 'success') {
    echo "✅ Entreprise créée avec succès\n";
    echo "ID Entreprise: " . ($responseData['entreprise_id'] ?? 'N/A') . "\n";
    echo "ID Contravention: " . ($responseData['contravention_id'] ?? 'N/A') . "\n";
    
    if (isset($responseData['pdf_generated']) && $responseData['pdf_generated']) {
        echo "✅ PDF généré automatiquement\n";
        echo "URL PDF: " . ($responseData['pdf_url'] ?? 'N/A') . "\n";
        
        // Vérifier que le fichier PDF existe
        if (isset($responseData['pdf_url'])) {
            $pdfPath = __DIR__ . str_replace('/api', '', $responseData['pdf_url']);
            if (file_exists($pdfPath)) {
                $fileSize = filesize($pdfPath);
                echo "✅ Fichier PDF confirmé (Taille: " . number_format($fileSize) . " octets)\n";
            } else {
                echo "⚠️  Fichier PDF non trouvé à: $pdfPath\n";
            }
        }
    } else {
        echo "⚠️  PDF non généré: " . ($responseData['pdf_error'] ?? 'Raison inconnue') . "\n";
    }
    
    echo "\n=== Test d'intégration réussi ===\n";
} else {
    echo "❌ Erreur lors de la création:\n";
    echo "Statut: " . ($responseData['status'] ?? 'inconnu') . "\n";
    echo "Message: " . ($responseData['message'] ?? 'Aucun message') . "\n";
    echo "\n=== Test d'intégration échoué ===\n";
}
?>
