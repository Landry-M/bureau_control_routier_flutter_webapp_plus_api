<?php
// Test spécifique pour vérifier l'affichage des contraventions d'entreprise
require_once 'api/config/database.php';
require_once 'api/controllers/ContraventionController.php';

echo "=== Test contravention entreprise - Libellés des champs ===\n\n";

try {
    // 1. Créer une contravention pour une entreprise
    echo "1. Création d'une contravention pour entreprise...\n";
    $contraventionController = new ContraventionController();
    
    $testData = [
        'dossier_id' => '1', // Supposons qu'il existe une entreprise avec ID 1
        'type_dossier' => 'entreprise',
        'date_infraction' => date('Y-m-d H:i:s'),
        'lieu' => 'Avenue Lumumba, Lubumbashi',
        'type_infraction' => 'Stationnement interdit',
        'description' => 'Test entreprise - libellés des champs',
        'reference_loi' => 'Art. 456',
        'amende' => '100000',
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
    echo "✅ Contravention entreprise créée avec ID: $contraventionId\n\n";
    
    // 2. Tester la page de prévisualisation pour entreprise
    echo "2. Test de la page de prévisualisation pour entreprise...\n";
    
    // Simuler une requête GET
    $_GET['id'] = $contraventionId;
    
    // Capturer la sortie de la page
    ob_start();
    
    try {
        include 'contravention_display.php';
        $output = ob_get_contents();
        
        // Vérifications spécifiques aux entreprises
        $checks = [
            'Nom de l\'entreprise' => 'Label entreprise correct',
            'RCCM' => 'Label RCCM pour entreprise',
            'Informations du contrevenant' => 'Section contrevenant',
            'Bureau de Contrôle Routier' => 'Titre institution',
            'CONTRAVENTION' => 'Titre principal'
        ];
        
        // Vérifications négatives (ne doivent PAS être présentes)
        $shouldNotExist = [
            'Nom et prénom' => 'Label particulier (ne doit pas être présent)',
            'N° Identité' => 'Label identité particulier (ne doit pas être présent)'
        ];
        
        echo "Vérifications positives:\n";
        foreach ($checks as $needle => $description) {
            if (strpos($output, $needle) !== false) {
                echo "✅ $description trouvé\n";
            } else {
                echo "❌ $description manquant\n";
            }
        }
        
        echo "\nVérifications négatives:\n";
        foreach ($shouldNotExist as $needle => $description) {
            if (strpos($output, $needle) === false) {
                echo "✅ $description correctement absent\n";
            } else {
                echo "❌ $description présent (ne devrait pas l'être)\n";
            }
        }
        
        // Sauvegarder la page générée pour inspection
        $htmlFile = "test_contravention_entreprise_$contraventionId.html";
        file_put_contents($htmlFile, $output);
        echo "\n✅ Page entreprise sauvegardée: $htmlFile\n";
        
    } catch (Exception $e) {
        echo "❌ Erreur lors de la génération: " . $e->getMessage() . "\n";
    } finally {
        ob_end_clean();
    }
    
    // 3. Créer aussi une contravention particulier pour comparaison
    echo "\n3. Création d'une contravention particulier pour comparaison...\n";
    
    $testDataParticulier = [
        'dossier_id' => '1', // Supposons qu'il existe un particulier avec ID 1
        'type_dossier' => 'particulier',
        'date_infraction' => date('Y-m-d H:i:s'),
        'lieu' => 'Avenue Lumumba, Lubumbashi',
        'type_infraction' => 'Excès de vitesse',
        'description' => 'Test particulier - libellés des champs',
        'reference_loi' => 'Art. 123',
        'amende' => '50000',
        'payed' => '0',
        'photos' => '',
        'latitude' => '-11.6689',
        'longitude' => '27.4794'
    ];
    
    $createResultParticulier = $contraventionController->create($testDataParticulier);
    
    if ($createResultParticulier['success']) {
        $contraventionIdParticulier = $createResultParticulier['id'];
        echo "✅ Contravention particulier créée avec ID: $contraventionIdParticulier\n";
        
        // Tester la page particulier
        $_GET['id'] = $contraventionIdParticulier;
        
        ob_start();
        try {
            include 'contravention_display.php';
            $outputParticulier = ob_get_contents();
            
            // Vérifier que les libellés particulier sont corrects
            if (strpos($outputParticulier, 'Nom et prénom') !== false) {
                echo "✅ Label 'Nom et prénom' correct pour particulier\n";
            } else {
                echo "❌ Label 'Nom et prénom' manquant pour particulier\n";
            }
            
            if (strpos($outputParticulier, 'N° Identité') !== false) {
                echo "✅ Label 'N° Identité' correct pour particulier\n";
            } else {
                echo "❌ Label 'N° Identité' manquant pour particulier\n";
            }
            
            $htmlFileParticulier = "test_contravention_particulier_$contraventionIdParticulier.html";
            file_put_contents($htmlFileParticulier, $outputParticulier);
            echo "✅ Page particulier sauvegardée: $htmlFileParticulier\n";
            
        } catch (Exception $e) {
            echo "❌ Erreur particulier: " . $e->getMessage() . "\n";
        } finally {
            ob_end_clean();
        }
    }
    
    echo "\n=== Comparaison des fichiers générés ===\n";
    echo "Entreprise: test_contravention_entreprise_$contraventionId.html\n";
    if (isset($contraventionIdParticulier)) {
        echo "Particulier: test_contravention_particulier_$contraventionIdParticulier.html\n";
    }
    echo "\nOuvrez ces fichiers pour vérifier visuellement les différences de libellés.\n";
    
    echo "\n=== Test terminé avec succès ===\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}
?>
