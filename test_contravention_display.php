<?php
// Test pour vérifier que contravention_display.php fonctionne correctement
require_once 'api/config/database.php';
require_once 'api/controllers/ContraventionController.php';

echo "=== Test de contravention_display.php ===\n\n";

try {
    // 1. Créer une contravention de test
    echo "1. Création d'une contravention de test...\n";
    $contraventionController = new ContraventionController();
    
    $testData = [
        'dossier_id' => '1',
        'type_dossier' => 'particulier',
        'date_infraction' => date('Y-m-d H:i:s'),
        'lieu' => 'Avenue Mobutu, Lubumbashi',
        'type_infraction' => 'Excès de vitesse',
        'description' => 'Test display page',
        'reference_loi' => 'Art. 123',
        'amende' => '50000',
        'payed' => '0',
        'photos' => '',
        'latitude' => '-11.6689',
        'longitude' => '27.4794'
    ];
    
    $createResult = $contraventionController->create($testData);
    
    if (!$createResult['success']) {
        throw new Exception('Échec de création: ' . $createResult['message']);
    }
    
    $contraventionId = $createResult['id'];
    echo "✅ Contravention créée avec ID: $contraventionId\n\n";
    
    // 2. Tester l'accès à la page de prévisualisation
    echo "2. Test d'accès à la page de prévisualisation...\n";
    
    // Simuler une requête GET
    $_GET['id'] = $contraventionId;
    
    // Capturer la sortie de la page
    ob_start();
    
    try {
        // Inclure la page de prévisualisation
        include 'contravention_display.php';
        $output = ob_get_contents();
        
        // Vérifier que la page contient les éléments attendus
        if (strpos($output, 'CONTRAVENTION') !== false) {
            echo "✅ Page générée avec succès\n";
        } else {
            echo "❌ Page générée mais contenu incorrect\n";
        }
        
        if (strpos($output, "N° $contraventionId") !== false) {
            echo "✅ ID de contravention affiché correctement\n";
        } else {
            echo "❌ ID de contravention non trouvé dans la page\n";
        }
        
        if (strpos($output, 'Avenue Mobutu') !== false) {
            echo "✅ Lieu d'infraction affiché\n";
        } else {
            echo "❌ Lieu d'infraction non trouvé\n";
        }
        
        if (strpos($output, 'Coordonnées géographiques') !== false) {
            echo "✅ Coordonnées géographiques affichées\n";
        } else {
            echo "❌ Coordonnées géographiques non trouvées\n";
        }
        
        // Sauvegarder la page générée pour inspection
        file_put_contents("test_contravention_$contraventionId.html", $output);
        echo "✅ Page sauvegardée: test_contravention_$contraventionId.html\n";
        
    } catch (Exception $e) {
        echo "❌ Erreur lors de la génération: " . $e->getMessage() . "\n";
    } finally {
        ob_end_clean();
    }
    
    echo "\n=== Test terminé avec succès ===\n";
    echo "Vous pouvez maintenant ouvrir test_contravention_$contraventionId.html dans un navigateur\n";
    echo "Ou accéder à: http://localhost/contravention_display.php?id=$contraventionId\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
