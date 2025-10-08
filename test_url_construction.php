<?php
// Test pour vérifier que les URLs sont correctement construites
require_once 'api/config/database.php';
require_once 'api/controllers/ContraventionController.php';

echo "=== Test de construction des URLs ===\n\n";

try {
    // 1. Tester la génération d'une contravention avec PDF
    echo "1. Test de génération de contravention avec PDF...\n";
    
    $contraventionController = new ContraventionController();
    
    $testData = [
        'dossier_id' => '1',
        'type_dossier' => 'particulier',
        'date_infraction' => date('Y-m-d H:i:s'),
        'lieu' => 'Test URL construction',
        'type_infraction' => 'Test',
        'description' => 'Test URL construction',
        'reference_loi' => 'Test',
        'amende' => '1000',
        'payed' => '0',
        'photos' => '',
        'latitude' => '-11.6689',
        'longitude' => '27.4794'
    ];
    
    $result = $contraventionController->create($testData);
    
    if ($result['success']) {
        $contraventionId = $result['id'];
        echo "✅ Contravention créée: ID $contraventionId\n";
        
        // Générer le PDF
        $pdfResult = $contraventionController->generatePdf($contraventionId);
        
        if ($pdfResult['success']) {
            $pdfUrl = $pdfResult['pdf_url'];
            echo "✅ PDF généré: $pdfUrl\n";
            
            // Vérifier le format de l'URL
            if (strpos($pdfUrl, '/api/uploads/contraventions/') === 0) {
                echo "✅ Format URL correct: commence par /api/uploads/contraventions/\n";
            } else {
                echo "❌ Format URL incorrect: $pdfUrl\n";
            }
            
            // Vérifier qu'il n'y a pas de duplication
            if (strpos($pdfUrl, '/api/routes/index.php') === false) {
                echo "✅ Pas de duplication /api/routes/index.php\n";
            } else {
                echo "❌ Duplication détectée: $pdfUrl\n";
            }
            
            // Construire l'URL complète comme le ferait Flutter
            $baseUrls = [
                'http://localhost:8000',
                'http://localhost:8000/api/routes/index.php', // Incorrect
                'http://localhost:8000' // Correct avec imageBaseUrl
            ];
            
            echo "\n📋 Test de construction d'URLs complètes:\n";
            
            foreach ($baseUrls as $baseUrl) {
                $fullUrl = $baseUrl . $pdfUrl;
                echo "Base: $baseUrl\n";
                echo "Résultat: $fullUrl\n";
                
                if (strpos($fullUrl, '/api/routes/index.php/api/') !== false) {
                    echo "❌ PROBLÈME: Duplication détectée!\n";
                } else {
                    echo "✅ URL correcte\n";
                }
                echo "---\n";
            }
        }
    }
    
    // 2. Tester les URLs d'images
    echo "\n2. Test des URLs d'images...\n";
    
    $imageExamples = [
        '/api/uploads/particuliers/photo_123.jpg',
        '/api/uploads/accidents/accident_456.png',
        '/api/uploads/vehicules/vehicule_789.jpeg'
    ];
    
    foreach ($imageExamples as $imagePath) {
        echo "Image: $imagePath\n";
        
        // Simuler la construction Flutter avec imageBaseUrl (correct)
        $correctUrl = 'http://localhost:8000' . $imagePath;
        echo "✅ Correct (imageBaseUrl): $correctUrl\n";
        
        // Simuler la construction Flutter avec baseUrl (incorrect)
        $incorrectUrl = 'http://localhost:8000/api/routes/index.php' . $imagePath;
        echo "❌ Incorrect (baseUrl): $incorrectUrl\n";
        echo "---\n";
    }
    
    // 3. Recommandations
    echo "\n=== Recommandations ===\n";
    echo "✅ Pour les appels API: utiliser ApiConfig.baseUrl\n";
    echo "✅ Pour les fichiers statiques: utiliser ApiConfig.imageBaseUrl\n";
    echo "✅ Les chemins retournés par l'API doivent commencer par /api/uploads/\n";
    echo "✅ Flutter doit construire: imageBaseUrl + chemin_api\n";
    echo "❌ Ne jamais utiliser: baseUrl + /api/uploads/\n";
    
    echo "\n=== Exemple de construction correcte ===\n";
    echo "// Dans Flutter:\n";
    echo "final pdfUrl = '\${ApiConfig.imageBaseUrl}\$pdfPath';\n";
    echo "// Résultat: http://localhost:8000/api/uploads/contraventions/file.pdf\n";
    
    echo "\n=== Exemple de construction incorrecte ===\n";
    echo "// Dans Flutter (À ÉVITER):\n";
    echo "final pdfUrl = '\${ApiConfig.baseUrl}\$pdfPath';\n";
    echo "// Résultat: http://localhost:8000/api/routes/index.php/api/uploads/contraventions/file.pdf\n";
    
    echo "\n=== Test terminé ===\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
