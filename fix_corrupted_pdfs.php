<?php
// Script pour corriger les PDF corrompus
require_once 'api/config/database.php';
require_once 'api/controllers/ContraventionController.php';

echo "=== Correction des PDF corrompus ===\n\n";

try {
    $uploadDir = __DIR__ . '/api/uploads/contraventions/';
    
    // 1. Analyser les PDF existants
    echo "1. Analyse des PDF existants...\n";
    
    $pdfFiles = glob($uploadDir . '*.pdf');
    $corruptedFiles = [];
    $validFiles = [];
    
    foreach ($pdfFiles as $file) {
        $filename = basename($file);
        $handle = fopen($file, 'rb');
        $header = fread($handle, 8);
        fclose($handle);
        
        if (strpos($header, '%PDF') === 0) {
            $validFiles[] = $filename;
            echo "✅ PDF valide: $filename\n";
        } else {
            $corruptedFiles[] = $filename;
            echo "❌ PDF corrompu: $filename\n";
        }
    }
    
    echo "\n📊 Résumé:\n";
    echo "✅ PDF valides: " . count($validFiles) . "\n";
    echo "❌ PDF corrompus: " . count($corruptedFiles) . "\n";
    
    // 2. Sauvegarder les fichiers corrompus
    if (!empty($corruptedFiles)) {
        echo "\n2. Sauvegarde des fichiers corrompus...\n";
        
        $backupDir = $uploadDir . 'corrupted_backup/';
        if (!is_dir($backupDir)) {
            mkdir($backupDir, 0755, true);
        }
        
        foreach ($corruptedFiles as $filename) {
            $source = $uploadDir . $filename;
            $backup = $backupDir . $filename . '.txt';
            
            if (copy($source, $backup)) {
                echo "💾 Sauvegardé: $filename → corrupted_backup/$filename.txt\n";
            }
        }
    }
    
    // 3. Régénérer les PDF corrompus
    if (!empty($corruptedFiles)) {
        echo "\n3. Régénération des PDF corrompus...\n";
        
        $contraventionController = new ContraventionController();
        
        foreach ($corruptedFiles as $filename) {
            // Extraire l'ID de la contravention du nom de fichier
            if (preg_match('/contravention_(\d+)_/', $filename, $matches)) {
                $contraventionId = (int)$matches[1];
                
                echo "🔄 Régénération PDF pour contravention ID: $contraventionId\n";
                
                try {
                    $result = $contraventionController->generatePdf($contraventionId);
                    
                    if ($result['success']) {
                        echo "✅ PDF régénéré: " . $result['pdf_url'] . "\n";
                        
                        // Supprimer l'ancien fichier corrompu
                        $oldFile = $uploadDir . $filename;
                        if (file_exists($oldFile)) {
                            unlink($oldFile);
                            echo "🗑️ Ancien fichier supprimé: $filename\n";
                        }
                    } else {
                        echo "❌ Échec régénération: " . $result['message'] . "\n";
                    }
                } catch (Exception $e) {
                    echo "❌ Erreur régénération ID $contraventionId: " . $e->getMessage() . "\n";
                }
            } else {
                echo "⚠️ Impossible d'extraire l'ID de: $filename\n";
            }
        }
    }
    
    // 4. Tester la génération d'un nouveau PDF
    echo "\n4. Test de génération d'un nouveau PDF...\n";
    
    $testData = [
        'dossier_id' => '1',
        'type_dossier' => 'particulier',
        'date_infraction' => date('Y-m-d H:i:s'),
        'lieu' => 'Test PDF correction',
        'type_infraction' => 'Test',
        'description' => 'Test de correction des PDF corrompus',
        'reference_loi' => 'Test',
        'amende' => '1000',
        'payed' => '0',
        'photos' => '',
        'latitude' => '-11.6689',
        'longitude' => '27.4794'
    ];
    
    $contraventionController = new ContraventionController();
    $createResult = $contraventionController->create($testData);
    
    if ($createResult['success']) {
        $contraventionId = $createResult['id'];
        echo "✅ Contravention de test créée: ID $contraventionId\n";
        
        $pdfResult = $contraventionController->generatePdf($contraventionId);
        
        if ($pdfResult['success']) {
            $pdfPath = __DIR__ . '/api' . $pdfResult['pdf_url'];
            echo "✅ PDF de test généré: " . $pdfResult['pdf_url'] . "\n";
            
            // Vérifier que le nouveau PDF est valide
            if (file_exists($pdfPath)) {
                $handle = fopen($pdfPath, 'rb');
                $header = fread($handle, 8);
                fclose($handle);
                
                if (strpos($header, '%PDF') === 0) {
                    echo "✅ Nouveau PDF valide (commence par %PDF)\n";
                    echo "📄 Taille: " . filesize($pdfPath) . " bytes\n";
                } else {
                    echo "❌ Nouveau PDF toujours corrompu\n";
                    echo "🔍 En-tête: " . bin2hex($header) . "\n";
                }
            } else {
                echo "❌ Fichier PDF non trouvé: $pdfPath\n";
            }
        } else {
            echo "❌ Échec génération PDF test: " . $pdfResult['message'] . "\n";
        }
    } else {
        echo "❌ Échec création contravention test: " . $createResult['message'] . "\n";
    }
    
    // 5. Vérifications finales
    echo "\n5. Vérifications finales...\n";
    
    // Vérifier wkhtmltopdf
    $wkhtmltopdf = shell_exec('which wkhtmltopdf 2>/dev/null');
    if (!empty($wkhtmltopdf)) {
        echo "✅ wkhtmltopdf disponible: " . trim($wkhtmltopdf) . "\n";
    } else {
        echo "⚠️ wkhtmltopdf non disponible - utilisation du PDF minimal\n";
        echo "💡 Pour installer: sudo apt-get install wkhtmltopdf (Ubuntu/Debian)\n";
        echo "💡 Pour installer: brew install wkhtmltopdf (macOS)\n";
    }
    
    // Compter les PDF finaux
    $finalPdfs = glob($uploadDir . '*.pdf');
    $validCount = 0;
    
    foreach ($finalPdfs as $file) {
        $handle = fopen($file, 'rb');
        $header = fread($handle, 8);
        fclose($handle);
        
        if (strpos($header, '%PDF') === 0) {
            $validCount++;
        }
    }
    
    echo "\n📊 État final:\n";
    echo "📁 Total PDF: " . count($finalPdfs) . "\n";
    echo "✅ PDF valides: $validCount\n";
    echo "❌ PDF corrompus: " . (count($finalPdfs) - $validCount) . "\n";
    
    if ($validCount === count($finalPdfs)) {
        echo "\n🎉 Tous les PDF sont maintenant valides!\n";
    } else {
        echo "\n⚠️ Il reste des PDF corrompus à corriger\n";
    }
    
    echo "\n=== Correction terminée ===\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}
?>
