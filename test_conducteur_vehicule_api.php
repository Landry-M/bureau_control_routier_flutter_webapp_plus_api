<?php
// Script de test pour l'API conducteur-vehicule

// Test de création d'un conducteur avec véhicule
$url = 'http://localhost:8000/api/routes/index.php/conducteur-vehicule/create';

// Données de test
$postData = [
    'nom' => 'Jean Dupont',
    'numero_permis' => 'CD123456789',
    'adresse' => '123 Avenue de la Paix, Lubumbashi',
    'observations' => 'Conducteur expérimenté',
    'date_naissance' => '1985-05-15T00:00:00.000Z',
    'permis_valide_le' => '2020-01-01T00:00:00.000Z',
    'permis_expire_le' => '2030-01-01T00:00:00.000Z',
    
    // Données véhicule
    'plaque' => 'TEST123CD',
    'marque' => 'Toyota',
    'modele' => 'Corolla',
    'couleur' => 'Blanc',
    'annee' => '2020',
    'chassis' => 'CH123456789',
    'moteur' => 'MT987654321',
    'proprietaire' => 'Jean Dupont',
    'usage' => 'Personnel',
    'date_importation' => '2020-06-01T00:00:00.000Z',
    'date_plaque' => '2020-07-01T00:00:00.000Z',
    
    // Contravention optionnelle
    'with_contravention' => 'true',
    'cv_lieu' => 'Avenue Lumumba',
    'cv_type_infraction' => 'Excès de vitesse',
    'cv_description' => 'Dépassement de la limite autorisée',
    'cv_reference_loi' => 'Art. 123',
    'cv_amende' => '50000',
    'cv_payed' => '0',
    'cv_date_infraction' => '2025-10-05T10:30:00.000Z',
    
    'username' => 'admin'
];

echo "=== TEST API CONDUCTEUR-VEHICULE ===\n";
echo "URL: $url\n";
echo "Données envoyées:\n";
print_r($postData);
echo "\n";

// Initialiser cURL
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($postData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/x-www-form-urlencoded'
]);

// Exécuter la requête
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "=== RÉPONSE ===\n";
echo "Code HTTP: $httpCode\n";

if ($error) {
    echo "Erreur cURL: $error\n";
} else {
    echo "Réponse brute:\n$response\n\n";
    
    $data = json_decode($response, true);
    if ($data) {
        echo "Réponse JSON décodée:\n";
        print_r($data);
        
        if (isset($data['success']) && $data['success']) {
            echo "\n✅ SUCCÈS: Conducteur et véhicule créés avec succès!\n";
            echo "ID Conducteur: " . ($data['conducteur_id'] ?? 'N/A') . "\n";
            echo "ID Véhicule: " . ($data['vehicule_id'] ?? 'N/A') . "\n";
            echo "ID Contravention: " . ($data['contravention_id'] ?? 'N/A') . "\n";
        } else {
            echo "\n❌ ERREUR: " . ($data['message'] ?? 'Erreur inconnue') . "\n";
        }
    } else {
        echo "Impossible de décoder la réponse JSON\n";
    }
}

echo "\n=== TEST LISTE CONDUCTEURS ===\n";
$listUrl = 'http://localhost:8000/api/routes/index.php/conducteurs?page=1&limit=5';
echo "URL: $listUrl\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $listUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Code HTTP: $httpCode\n";
echo "Réponse:\n$response\n";

$data = json_decode($response, true);
if ($data && isset($data['success']) && $data['success']) {
    echo "\n✅ SUCCÈS: Liste récupérée!\n";
    echo "Nombre de conducteurs: " . count($data['data']) . "\n";
    echo "Total: " . ($data['pagination']['total'] ?? 'N/A') . "\n";
} else {
    echo "\n❌ ERREUR lors de la récupération de la liste\n";
}
?>
