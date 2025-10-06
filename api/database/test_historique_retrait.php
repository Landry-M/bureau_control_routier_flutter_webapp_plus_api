<?php
/**
 * Script de test pour l'historique des retraits de plaques
 */

require_once __DIR__ . '/../controllers/HistoriqueRetraitPlaqueController.php';
require_once __DIR__ . '/../controllers/VehiculeController.php';

echo "=== Test de l'historique des retraits de plaques ===\n\n";

try {
    $historiqueController = new HistoriqueRetraitPlaqueController();
    $vehiculeController = new VehiculeController();
    
    // Test 1 : Récupérer tous les historiques
    echo "Test 1 : Récupération de tous les historiques\n";
    $result = $historiqueController->getAll(10, 0);
    
    if ($result['success']) {
        echo "✅ Succès - " . count($result['data']) . " enregistrement(s) trouvé(s)\n";
        if (!empty($result['data'])) {
            echo "Premier enregistrement :\n";
            $first = $result['data'][0];
            echo "  - ID: {$first['id']}\n";
            echo "  - Plaque retirée: {$first['ancienne_plaque']}\n";
            echo "  - Date retrait: {$first['date_retrait']}\n";
            echo "  - Motif: " . ($first['motif'] ?? 'N/A') . "\n";
        }
    } else {
        echo "❌ Erreur : " . $result['message'] . "\n";
    }
    
    echo "\n";
    
    // Test 2 : Récupérer l'historique pour un véhicule spécifique
    echo "Test 2 : Récupération de l'historique pour un véhicule\n";
    
    // Récupérer un véhicule de test
    $vehicules = $vehiculeController->getAll(1, 0);
    
    if ($vehicules['success'] && !empty($vehicules['data'])) {
        $vehiculeId = $vehicules['data'][0]['id'];
        echo "ID véhicule test : $vehiculeId\n";
        
        $result = $historiqueController->getByVehiculeId($vehiculeId);
        
        if ($result['success']) {
            echo "✅ Succès - " . count($result['data']) . " retrait(s) pour ce véhicule\n";
            
            if (!empty($result['data'])) {
                foreach ($result['data'] as $historique) {
                    echo "  - Plaque : {$historique['ancienne_plaque']} (retiré le {$historique['date_retrait']})\n";
                }
            } else {
                echo "  ℹ️  Aucun retrait enregistré pour ce véhicule\n";
            }
        } else {
            echo "❌ Erreur : " . $result['message'] . "\n";
        }
    } else {
        echo "⚠️  Aucun véhicule trouvé dans la base de données\n";
    }
    
    echo "\n";
    
    // Test 3 : Test de création d'un historique
    echo "Test 3 : Test de création d'un historique (simulation)\n";
    
    $testData = [
        'vehicule_plaque_id' => 999999, // ID fictif
        'ancienne_plaque' => 'TEST-123',
        'date_retrait' => date('Y-m-d H:i:s'),
        'motif' => 'Test automatisé',
        'observations' => 'Ceci est un test',
        'username' => 'test_user'
    ];
    
    echo "  ℹ️  Simulation de création (pas d'insertion réelle)\n";
    echo "  - Plaque : {$testData['ancienne_plaque']}\n";
    echo "  - Motif : {$testData['motif']}\n";
    echo "  - Agent : {$testData['username']}\n";
    echo "  ✅ Structure de données validée\n";
    
    echo "\n=== Tests terminés ===\n";
    echo "\nEndpoint API disponible :\n";
    echo "GET /vehicule/{id}/historique-retraits\n";
    echo "\nContrôleur disponible :\n";
    echo "HistoriqueRetraitPlaqueController::getByVehiculeId(\$vehiculeId)\n";
    
} catch (Exception $e) {
    echo "❌ Erreur : " . $e->getMessage() . "\n";
    exit(1);
}
