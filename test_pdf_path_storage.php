<?php
// Test pour vérifier que le chemin du PDF est bien enregistré dans la base de données
require_once 'api/config/database.php';
require_once 'api/controllers/ContraventionController.php';

echo "=== Test d'enregistrement du chemin PDF ===\n\n";

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
        'description' => 'Test PDF path storage',
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
    
    // 2. Générer le PDF
    echo "2. Génération du PDF...\n";
    $pdfResult = $contraventionController->generatePdf($contraventionId);
    
    if (!$pdfResult['success']) {
        throw new Exception('Échec génération PDF: ' . $pdfResult['message']);
    }
    
    echo "✅ PDF généré: " . $pdfResult['pdf_url'] . "\n\n";
    
    // 3. Vérifier que le chemin est enregistré en base
    echo "3. Vérification en base de données...\n";
    $contraventionData = $contraventionController->getById($contraventionId);
    
    if (!$contraventionData['success']) {
        throw new Exception('Échec récupération: ' . $contraventionData['message']);
    }
    
    $contravention = $contraventionData['data'];
    
    echo "Données récupérées:\n";
    echo "- ID: " . $contravention['id'] . "\n";
    echo "- Lieu: " . $contravention['lieu'] . "\n";
    echo "- Latitude: " . ($contravention['latitude'] ?? 'NULL') . "\n";
    echo "- Longitude: " . ($contravention['longitude'] ?? 'NULL') . "\n";
    echo "- PDF Path: " . ($contravention['pdf_path'] ?? 'NULL') . "\n\n";
    
    // 4. Vérifications
    if (isset($contravention['pdf_path']) && !empty($contravention['pdf_path'])) {
        echo "✅ Le chemin PDF est bien enregistré: " . $contravention['pdf_path'] . "\n";
        
        // Vérifier si le fichier existe
        $fullPath = __DIR__ . '/api' . $contravention['pdf_path'];
        if (file_exists($fullPath)) {
            echo "✅ Le fichier PDF existe sur le disque\n";
            echo "   Taille: " . filesize($fullPath) . " bytes\n";
        } else {
            echo "❌ Le fichier PDF n'existe pas sur le disque: $fullPath\n";
        }
    } else {
        echo "❌ Le chemin PDF n'est PAS enregistré en base\n";
    }
    
    // 5. Vérifier les coordonnées géographiques
    if (isset($contravention['latitude']) && isset($contravention['longitude'])) {
        echo "✅ Les coordonnées géographiques sont enregistrées\n";
        echo "   Latitude: " . $contravention['latitude'] . "\n";
        echo "   Longitude: " . $contravention['longitude'] . "\n";
    } else {
        echo "❌ Les coordonnées géographiques ne sont PAS enregistrées\n";
    }
    
    echo "\n=== Test terminé avec succès ===\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}
?>
