<?php
// Script de test pour vérifier l'API des véhicules et plaques temporaires

// Configuration
$baseUrl = 'http://localhost/bcr/api/routes/index.php';

// Fonction pour faire une requête HTTP
function makeRequest($url, $method = 'GET', $data = null, $files = null) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HEADER, false);
    
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        if ($files) {
            // Pour les fichiers, utiliser multipart/form-data
            curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
        } elseif ($data) {
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

echo "=== Test de l'API Véhicules BCR ===\n\n";

// Test 1: Vérifier l'endpoint de test
echo "1. Test GET / (endpoint de test)\n";
$response = makeRequest($baseUrl . '?route=/test');
echo "Code HTTP: " . $response['code'] . "\n";
echo "Réponse: " . $response['body'] . "\n\n";

// Test 2: Connexion avec les identifiants de la mémoire
echo "2. Test POST /auth/login\n";
$loginData = [
    'matricule' => 'admin',
    'password' => 'password123'
];
$response = makeRequest($baseUrl . '?route=/auth/login', 'POST', $loginData);
echo "Code HTTP: " . $response['code'] . "\n";
echo "Réponse: " . $response['body'] . "\n\n";

// Test 3: Recherche de plaque locale (vide au début)
echo "3. Test GET /vehicules/search\n";
$response = makeRequest($baseUrl . '?route=/vehicules/search&q=TEST123');
echo "Code HTTP: " . $response['code'] . "\n";
echo "Réponse: " . $response['body'] . "\n\n";

// Test 4: Création d'un véhicule simple
echo "4. Test POST /create-vehicule-plaque\n";
$vehiculeData = [
    'marque' => 'Toyota',
    'modele' => 'Corolla',
    'annee' => '2020',
    'couleur' => 'Blanc',
    'numero_chassis' => 'TEST123456789',
    'plaque' => 'TEST123',
    'genre' => 'Voiture particulière',
    'usage' => 'Personnel',
    'nume_assurance' => 'ASS001',
    'societe_assurance' => 'SONAS'
];
$response = makeRequest($baseUrl . '?route=/create-vehicule-plaque', 'POST', $vehiculeData);
echo "Code HTTP: " . $response['code'] . "\n";
echo "Réponse: " . $response['body'] . "\n\n";

$vehiculeId = null;
if ($response['data'] && $response['data']['state']) {
    $vehiculeId = $response['data']['vehicule_id'];
    echo "Véhicule créé avec ID: $vehiculeId\n\n";
}

// Test 5: Création d'un véhicule avec contravention
echo "5. Test POST /create-vehicule-with-contravention\n";
$vehiculeAvecContraventionData = [
    'marque' => 'Honda',
    'modele' => 'Civic',
    'annee' => '2019',
    'couleur' => 'Rouge',
    'numero_chassis' => 'HONDA123456789',
    'plaque' => 'HON456',
    'with_contravention' => '1',
    'cv_date_infraction' => date('Y-m-d H:i:s'),
    'cv_lieu' => 'Avenue Lumumba, Kinshasa',
    'cv_type_infraction' => 'Excès de vitesse',
    'cv_description' => 'Véhicule roulant à 80 km/h dans une zone limitée à 50 km/h',
    'cv_reference_loi' => 'Art. 15 Code de la route',
    'cv_amende' => '50000',
    'cv_payed' => '0'
];
$response = makeRequest($baseUrl . '?route=/create-vehicule-with-contravention', 'POST', $vehiculeAvecContraventionData);
echo "Code HTTP: " . $response['code'] . "\n";
echo "Réponse: " . $response['body'] . "\n\n";

// Test 6: Liste des véhicules
echo "6. Test GET /vehicules\n";
$response = makeRequest($baseUrl . '?route=/vehicules&page=1&limit=10');
echo "Code HTTP: " . $response['code'] . "\n";
echo "Réponse: " . $response['body'] . "\n\n";

// Test 7: Création d'une plaque temporaire (si on a un véhicule)
if ($vehiculeId) {
    echo "7. Test POST /permis-temporaire/create\n";
    $plaqueTemporaireData = [
        'cible_type' => 'vehicule_plaque',
        'cible_id' => $vehiculeId,
        'motif' => 'plaque_temporaire',
        'date_debut' => date('Y-m-d'),
        'date_fin' => date('Y-m-d', strtotime('+30 days'))
    ];
    $response = makeRequest($baseUrl . '?route=/permis-temporaire/create', 'POST', $plaqueTemporaireData);
    echo "Code HTTP: " . $response['code'] . "\n";
    echo "Réponse: " . $response['body'] . "\n\n";
}

// Test 8: Recherche externe DGI (simulation)
echo "8. Test GET /api/vehicules/fetch-externe\n";
$response = makeRequest($baseUrl . '?route=/api/vehicules/fetch-externe&plate=CD123ABC');
echo "Code HTTP: " . $response['code'] . "\n";
echo "Réponse: " . $response['body'] . "\n\n";

// Test 9: Vérifier les logs après les actions
echo "9. Test GET /logs (après actions)\n";
$response = makeRequest($baseUrl . '?route=/logs&limit=10');
echo "Code HTTP: " . $response['code'] . "\n";
echo "Réponse: " . $response['body'] . "\n\n";

// Test 10: Détails d'un véhicule (si on a un ID)
if ($vehiculeId) {
    echo "10. Test GET /vehicules/{$vehiculeId}\n";
    $response = makeRequest($baseUrl . "?route=/vehicules/{$vehiculeId}");
    echo "Code HTTP: " . $response['code'] . "\n";
    echo "Réponse: " . $response['body'] . "\n\n";
}

echo "=== Fin des tests ===\n";
echo "\nPour tester l'interface Flutter:\n";
echo "1. Lancez l'application Flutter Web\n";
echo "2. Connectez-vous avec admin/password123\n";
echo "3. Cliquez sur 'Créer un dossier' depuis le dashboard\n";
echo "4. Testez la création de véhicules avec le modal\n";
echo "5. Vérifiez les logs dans le rapport d'activités\n";
?>
