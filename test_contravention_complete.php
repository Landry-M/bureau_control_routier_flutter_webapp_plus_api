<?php
// Test complet de la fonctionnalité contravention avec PDF et images
require_once 'api/config/database.php';
require_once 'api/controllers/ContraventionController.php';

echo "=== Test complet contravention avec PDF et images ===\n\n";

try {
    // 1. Vérifier que les images existent
    echo "1. Vérification des images...\n";
    $drapeau = __DIR__ . '/api/assets/images/drapeau.png';
    $logo = __DIR__ . '/api/assets/images/logo.png';
    
    if (file_exists($drapeau)) {
        echo "✅ Drapeau trouvé: " . filesize($drapeau) . " bytes\n";
    } else {
        echo "❌ Drapeau manquant: $drapeau\n";
    }
    
    if (file_exists($logo)) {
        echo "✅ Logo trouvé: " . filesize($logo) . " bytes\n";
    } else {
        echo "❌ Logo manquant: $logo\n";
    }
    
    // 2. Créer une contravention de test
    echo "\n2. Création d'une contravention de test...\n";
    $contraventionController = new ContraventionController();
    
    $testData = [
        'dossier_id' => '1',
        'type_dossier' => 'particulier',
        'date_infraction' => date('Y-m-d H:i:s'),
        'lieu' => 'Avenue Mobutu, Lubumbashi',
        'type_infraction' => 'Excès de vitesse',
        'description' => 'Test complet avec PDF et images',
        'reference_loi' => 'Art. 123',
        'amende' => '75000',
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
    echo "✅ Contravention créée avec ID: $contraventionId\n";
    
    // 3. Vérifier que le PDF a été généré automatiquement
    echo "\n3. Vérification de la génération automatique du PDF...\n";
    $contraventionData = $contraventionController->getById($contraventionId);
    
    if ($contraventionData['success']) {
        $contravention = $contraventionData['data'];
        if (!empty($contravention['pdf_path'])) {
            echo "✅ PDF path enregistré: " . $contravention['pdf_path'] . "\n";
            
            $pdfFile = __DIR__ . '/api' . $contravention['pdf_path'];
            if (file_exists($pdfFile)) {
                echo "✅ Fichier PDF existe: " . filesize($pdfFile) . " bytes\n";
            } else {
                echo "❌ Fichier PDF manquant: $pdfFile\n";
            }
        } else {
            echo "❌ Aucun PDF path enregistré\n";
        }
    }
    
    // 4. Tester la page de prévisualisation
    echo "\n4. Test de la page de prévisualisation...\n";
    
    // Simuler une requête GET
    $_GET['id'] = $contraventionId;
    
    // Capturer la sortie de la page
    ob_start();
    
    try {
        include 'contravention_display.php';
        $output = ob_get_contents();
        
        // Vérifications
        $checks = [
            'Bureau de Contrôle Routier' => 'Titre de l\'institution',
            'CONTRAVENTION' => 'Titre principal',
            "N° $contraventionId" => 'Numéro de contravention',
            'drapeau.png' => 'Image du drapeau',
            'logo.png' => 'Image du logo',
            'Avenue Mobutu' => 'Lieu d\'infraction',
            'Coordonnées géographiques' => 'Section coordonnées',
            'downloadPDF()' => 'Fonction de téléchargement',
            'html2canvas' => 'Librairie de capture',
            'jspdf' => 'Librairie PDF',
            'Nom et prénom' => 'Label pour particulier (type_dossier=particulier)'
        ];
        
        foreach ($checks as $needle => $description) {
            if (strpos($output, $needle) !== false) {
                echo "✅ $description trouvé\n";
            } else {
                echo "❌ $description manquant\n";
            }
        }
        
        // Sauvegarder la page générée
        $htmlFile = "test_contravention_complete_$contraventionId.html";
        file_put_contents($htmlFile, $output);
        echo "✅ Page sauvegardée: $htmlFile\n";
        
    } catch (Exception $e) {
        echo "❌ Erreur lors de la génération: " . $e->getMessage() . "\n";
    } finally {
        ob_end_clean();
    }
    
    // 5. Informations pour tester manuellement
    echo "\n5. Tests manuels recommandés:\n";
    echo "- Ouvrir $htmlFile dans un navigateur\n";
    echo "- Vérifier que les images s'affichent correctement\n";
    echo "- Tester le bouton 'Télécharger PDF'\n";
    echo "- Vérifier que le PDF généré contient les images\n";
    echo "- Accéder à: http://localhost/contravention_display.php?id=$contraventionId\n";
    
    echo "\n=== Test terminé avec succès ===\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}
?>
