<?php
/**
 * Script de test pour la génération de PDF de contraventions
 */

require_once __DIR__ . '/controllers/ContraventionController.php';
require_once __DIR__ . '/config/database.php';

echo "=== Test de génération de PDF pour contraventions ===\n\n";

try {
    // Test 1: Vérifier la connexion à la base de données
    echo "1. Test de connexion à la base de données...\n";
    $database = new Database();
    $db = $database->getConnection();
    if (!$db) {
        throw new Exception('Échec de connexion à la base de données');
    }
    echo "✅ Connexion réussie\n\n";

    // Test 2: Vérifier l'existence du dossier uploads/contraventions
    echo "2. Vérification du dossier uploads/contraventions...\n";
    $uploadsDir = __DIR__ . '/uploads/contraventions';
    if (!is_dir($uploadsDir)) {
        mkdir($uploadsDir, 0777, true);
        echo "📁 Dossier créé: $uploadsDir\n";
    } else {
        echo "✅ Dossier existe: $uploadsDir\n";
    }
    
    // Vérifier les permissions
    if (is_writable($uploadsDir)) {
        echo "✅ Dossier accessible en écriture\n\n";
    } else {
        echo "⚠️  Attention: Dossier non accessible en écriture\n\n";
    }

    // Test 3: Créer une contravention de test
    echo "3. Création d'une contravention de test...\n";
    $stmt = $db->prepare("INSERT INTO contraventions (
        dossier_id, type_dossier, date_infraction, lieu, type_infraction, 
        description, reference_loi, amende, payed, photos
    ) VALUES (
        '999', 'test', :date_infraction, 'Kinshasa - Avenue Kasa-Vubu', 
        'Excès de vitesse', 'Test de génération PDF', 'Art. 123 Code de la route', 
        '50000', 'non', ''
    )");
    
    $testDate = date('Y-m-d H:i:s');
    $stmt->bindParam(':date_infraction', $testDate);
    
    if ($stmt->execute()) {
        $contraventionId = $db->lastInsertId();
        echo "✅ Contravention de test créée (ID: $contraventionId)\n\n";
        
        // Test 4: Générer le PDF
        echo "4. Génération du PDF...\n";
        $contraventionController = new ContraventionController();
        $result = $contraventionController->generatePdf($contraventionId);
        
        if ($result['success']) {
            echo "✅ PDF généré avec succès\n";
            echo "📄 URL: " . $result['pdf_url'] . "\n";
            echo "📁 Chemin: " . $result['pdf_path'] . "\n";
            
            // Vérifier que le fichier existe
            if (file_exists($result['pdf_path'])) {
                $fileSize = filesize($result['pdf_path']);
                echo "✅ Fichier PDF créé (Taille: " . number_format($fileSize) . " octets)\n";
            } else {
                echo "❌ Fichier PDF non trouvé sur le disque\n";
            }
        } else {
            echo "❌ Erreur lors de la génération du PDF: " . $result['message'] . "\n";
        }
        
        // Test 5: Nettoyer les données de test
        echo "\n5. Nettoyage des données de test...\n";
        $cleanupStmt = $db->prepare("DELETE FROM contraventions WHERE id = :id");
        $cleanupStmt->bindParam(':id', $contraventionId);
        if ($cleanupStmt->execute()) {
            echo "✅ Contravention de test supprimée\n";
        }
        
    } else {
        throw new Exception('Échec de création de la contravention de test');
    }

    echo "\n=== Test terminé avec succès ===\n";

} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "\n=== Test échoué ===\n";
}
?>
