<?php
echo "=== TEST DE LA RECHERCHE GLOBALE ===\n\n";

// Test 1: Recherche globale
echo "1. Test de recherche globale avec le terme 'Toyota'...\n";
$url = 'http://localhost:8000/api/routes/index.php/search/global?q=Toyota&username=test_user';
$result = @file_get_contents($url);

if ($result === false) {
    echo "❌ Erreur lors de l'appel API de recherche\n";
} else {
    $data = json_decode($result, true);
    if ($data && $data['success']) {
        echo "✅ Recherche réussie ! Résultats trouvés: " . $data['total'] . "\n";
        echo "Types de résultats:\n";
        foreach ($data['data'] as $item) {
            echo "  - " . $item['type_label'] . ": " . $item['title'] . "\n";
        }
        
        // Test 2: Détails d'un résultat
        if (!empty($data['data'])) {
            $firstResult = $data['data'][0];
            $type = $firstResult['type'];
            $id = $firstResult['id'];
            
            echo "\n2. Test de récupération des détails pour {$type} ID {$id}...\n";
            $detailsUrl = "http://localhost:8000/api/routes/index.php/search/details/{$type}/{$id}?username=test_user";
            $detailsResult = @file_get_contents($detailsUrl);
            
            if ($detailsResult === false) {
                echo "❌ Erreur lors de la récupération des détails\n";
            } else {
                $detailsData = json_decode($detailsResult, true);
                if ($detailsData && $detailsData['success']) {
                    echo "✅ Détails récupérés avec succès !\n";
                    echo "Type: " . $detailsData['type'] . "\n";
                    echo "Données principales: " . count($detailsData['main_data']) . " champs\n";
                    echo "Données liées: " . count($detailsData['related_data']) . " sections\n";
                } else {
                    echo "❌ Erreur dans les détails: " . ($detailsData['message'] ?? 'Inconnue') . "\n";
                }
            }
        }
    } else {
        echo "❌ Erreur dans la recherche: " . ($data['message'] ?? 'Inconnue') . "\n";
    }
}

echo "\n3. Test de recherche avec terme vide...\n";
$emptyUrl = 'http://localhost:8000/api/routes/index.php/search/global?q=&username=test_user';
$emptyResult = @file_get_contents($emptyUrl);

if ($emptyResult !== false) {
    $emptyData = json_decode($emptyResult, true);
    if ($emptyData && !$emptyData['success']) {
        echo "✅ Gestion correcte des termes vides\n";
    } else {
        echo "❌ Problème avec la gestion des termes vides\n";
    }
}

echo "\n=== FIN DU TEST ===\n";
?>
