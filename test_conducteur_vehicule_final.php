<?php
// Test final de l'API conducteur-vehicule avec une nouvelle plaque

$url = 'http://localhost:8000/api/routes/index.php/conducteur-vehicule/create';

// Données de test avec une nouvelle plaque
$postData = [
    'nom' => 'Marie Kabila',
    'numero_permis' => 'CD987654321',
    'adresse' => '456 Boulevard Mobutu, Kinshasa',
    'observations' => 'Conductrice professionnelle',
    'date_naissance' => '1990-03-20T00:00:00.000Z',
    'permis_valide_le' => '2021-06-01T00:00:00.000Z',
    'permis_expire_le' => '2031-06-01T00:00:00.000Z',
    
    // Données véhicule
    'plaque' => 'FINAL456CD',
    'marque' => 'Honda',
    'modele' => 'Civic',
    'couleur' => 'Rouge',
    'annee' => '2021',
    'chassis' => 'HC987654321',
    'moteur' => 'HM123456789',
    'proprietaire' => 'Marie Kabila',
    'usage' => 'Commercial',
    'date_importation' => '2021-08-15T00:00:00.000Z',
    'date_plaque' => '2021-09-01T00:00:00.000Z',
    
    // Contravention optionnelle
    'with_contravention' => 'true',
    'cv_lieu' => 'Boulevard du 30 Juin',
    'cv_type_infraction' => 'Stationnement interdit',
    'cv_description' => 'Véhicule stationné en zone interdite',
    'cv_reference_loi' => 'Art. 456',
    'cv_amende' => '25000',
    'cv_payed' => '1',
    'cv_date_infraction' => '2025-10-05T11:45:00.000Z',
    
    'username' => 'admin'
];

echo "=== TEST FINAL API CONDUCTEUR-VEHICULE ===\n";
echo "Création de: " . $postData['nom'] . " avec véhicule " . $postData['plaque'] . "\n\n";

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

echo "=== RÉSULTAT ===\n";
echo "Code HTTP: $httpCode\n";

if ($error) {
    echo "❌ Erreur cURL: $error\n";
} else {
    $data = json_decode($response, true);
    if ($data && isset($data['success']) && $data['success']) {
        echo "✅ SUCCÈS COMPLET!\n\n";
        echo "📋 DÉTAILS DE LA CRÉATION:\n";
        echo "- Conducteur ID: " . $data['conducteur_id'] . "\n";
        echo "- Véhicule ID: " . $data['vehicule_id'] . "\n";
        
        if (isset($data['contravention_id']) && is_numeric($data['contravention_id'])) {
            echo "- Contravention ID: " . $data['contravention_id'] . "\n";
            echo "- Contravention: ✅ Créée avec succès\n";
        } else {
            echo "- Contravention: ⚠️ Erreur lors de la création\n";
            if (is_array($data['contravention_id'])) {
                echo "  Erreur: " . $data['contravention_id']['message'] . "\n";
            }
        }
        
        echo "\n🎉 FONCTIONNALITÉ OPÉRATIONNELLE!\n";
        echo "La modal conducteur-véhicule peut maintenant être utilisée dans l'application Flutter.\n";
        
    } else {
        echo "❌ ERREUR: " . ($data['message'] ?? 'Erreur inconnue') . "\n";
        echo "Réponse complète: $response\n";
    }
}

// Test de la liste mise à jour
echo "\n=== VÉRIFICATION LISTE CONDUCTEURS ===\n";
$listUrl = 'http://localhost:8000/api/routes/index.php/conducteurs?page=1&limit=10';

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $listUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($httpCode == 200) {
    $data = json_decode($response, true);
    if ($data && isset($data['success']) && $data['success']) {
        echo "✅ Liste récupérée avec succès!\n";
        echo "📊 STATISTIQUES:\n";
        echo "- Nombre total de conducteurs: " . $data['pagination']['total'] . "\n";
        echo "- Conducteurs affichés: " . count($data['data']) . "\n\n";
        
        echo "👥 LISTE DES CONDUCTEURS:\n";
        foreach ($data['data'] as $index => $conducteur) {
            echo ($index + 1) . ". " . $conducteur['nom'] . " (ID: " . $conducteur['id'] . ")\n";
            echo "   - Permis: " . ($conducteur['numero_permis'] ?? 'N/A') . "\n";
            echo "   - Créé le: " . $conducteur['created_at'] . "\n\n";
        }
    }
}

echo "=== TEST TERMINÉ ===\n";
?>
