<?php
// Script de vérification complète de la cohérence des uploads
echo "=== Vérification complète de la cohérence des uploads ===\n\n";

// 1. Vérifier la structure des dossiers
echo "1. Vérification de la structure des dossiers...\n";

$expectedDirs = [
    '/api/uploads/accidents',
    '/api/uploads/contraventions', 
    '/api/uploads/entreprises',
    '/api/uploads/particuliers',
    '/api/uploads/permis_temporaire',
    '/api/uploads/vehicules',
    '/api/uploads/conducteurs'
];

foreach ($expectedDirs as $dir) {
    $fullPath = __DIR__ . $dir;
    if (is_dir($fullPath)) {
        $fileCount = count(scandir($fullPath)) - 2;
        echo "✅ $dir ($fileCount fichiers)\n";
    } else {
        echo "❌ $dir (manquant)\n";
        mkdir($fullPath, 0755, true);
        echo "📁 Dossier créé: $dir\n";
    }
}

// 2. Vérifier les chemins dans le code PHP
echo "\n2. Vérification des chemins dans le code PHP...\n";

$phpFiles = [
    'api/controllers/ContraventionController.php',
    'api/controllers/ParticulierController.php', 
    'api/controllers/AccidentRapportController.php',
    'api/controllers/ConducteurVehiculeController.php',
    'api/controllers/PermisTemporaireController.php',
    'api/routes/index.php'
];

$correctPatterns = [
    '__DIR__ . \'/../uploads/',
    '/api/uploads/',
    'api/uploads/'
];

$incorrectPatterns = [
    '__DIR__ . \'/../../uploads/',
    '/uploads/',
    '../uploads/'
];

foreach ($phpFiles as $file) {
    $fullPath = __DIR__ . '/' . $file;
    if (file_exists($fullPath)) {
        $content = file_get_contents($fullPath);
        
        echo "📄 Vérification de $file...\n";
        
        // Vérifier les patterns incorrects
        $hasErrors = false;
        foreach ($incorrectPatterns as $pattern) {
            if (strpos($content, $pattern) !== false) {
                echo "  ❌ Pattern incorrect trouvé: $pattern\n";
                $hasErrors = true;
            }
        }
        
        // Vérifier les patterns corrects
        $hasCorrect = false;
        foreach ($correctPatterns as $pattern) {
            if (strpos($content, $pattern) !== false) {
                $hasCorrect = true;
                break;
            }
        }
        
        if (!$hasErrors && $hasCorrect) {
            echo "  ✅ Chemins corrects\n";
        } elseif (!$hasErrors && !$hasCorrect) {
            echo "  ⚠️ Aucun pattern d'upload trouvé\n";
        }
    } else {
        echo "❌ Fichier manquant: $file\n";
    }
}

// 3. Vérifier les chemins dans le code Dart/Flutter
echo "\n3. Vérification des chemins dans le code Flutter...\n";

$flutterFiles = [
    'lib/screens/accidents_screen.dart',
    'lib/widgets/particulier_details_modal.dart',
    'lib/widgets/entreprise_details_modal.dart'
];

foreach ($flutterFiles as $file) {
    $fullPath = __DIR__ . '/' . $file;
    if (file_exists($fullPath)) {
        $content = file_get_contents($fullPath);
        
        echo "📱 Vérification de $file...\n";
        
        // Vérifier les patterns incorrects
        if (strpos($content, '/uploads/') !== false && strpos($content, '/api/uploads/') === false) {
            echo "  ❌ Pattern incorrect trouvé: /uploads/ (sans api/)\n";
        } else {
            echo "  ✅ Chemins corrects ou aucun upload trouvé\n";
        }
    }
}

// 4. Tester la génération de PDF
echo "\n4. Test de génération de PDF...\n";

try {
    require_once 'api/controllers/ContraventionController.php';
    require_once 'api/config/database.php';
    
    $controller = new ContraventionController();
    
    // Créer une contravention de test
    $testData = [
        'dossier_id' => '1',
        'type_dossier' => 'particulier',
        'date_infraction' => date('Y-m-d H:i:s'),
        'lieu' => 'Test uploads consistency',
        'type_infraction' => 'Test',
        'description' => 'Test de cohérence uploads',
        'reference_loi' => 'Test',
        'amende' => '1000',
        'payed' => '0',
        'photos' => '',
        'latitude' => '-11.6689',
        'longitude' => '27.4794'
    ];
    
    $result = $controller->create($testData);
    
    if ($result['success']) {
        $contraventionId = $result['id'];
        echo "✅ Contravention de test créée: ID $contraventionId\n";
        
        // Tester la génération de PDF
        $pdfResult = $controller->generatePdf($contraventionId);
        
        if ($pdfResult['success']) {
            echo "✅ PDF généré: " . $pdfResult['pdf_url'] . "\n";
            
            // Vérifier que le fichier existe
            $pdfPath = __DIR__ . '/api' . $pdfResult['pdf_url'];
            if (file_exists($pdfPath)) {
                echo "✅ Fichier PDF existe sur le disque\n";
            } else {
                echo "❌ Fichier PDF manquant: $pdfPath\n";
            }
        } else {
            echo "❌ Échec génération PDF: " . $pdfResult['message'] . "\n";
        }
    } else {
        echo "❌ Échec création contravention: " . $result['message'] . "\n";
    }
    
} catch (Exception $e) {
    echo "❌ Erreur test PDF: " . $e->getMessage() . "\n";
}

// 5. Résumé et recommandations
echo "\n=== Résumé et recommandations ===\n";

$recommendations = [
    "✅ Tous les uploads doivent aller dans /api/uploads/[sous-dossier]/",
    "✅ Les chemins PHP doivent utiliser __DIR__ . '/../uploads/[sous-dossier]/'",
    "✅ Les URLs retournées doivent commencer par /api/uploads/",
    "✅ Le code Flutter doit utiliser /api/uploads/ dans les URLs",
    "✅ Migrer les fichiers existants avec migrate_uploads_to_api.php",
    "✅ Tester l'affichage des images après migration",
    "✅ Configurer le serveur web pour servir api/uploads/"
];

foreach ($recommendations as $rec) {
    echo "$rec\n";
}

echo "\n=== Vérification terminée ===\n";
?>
