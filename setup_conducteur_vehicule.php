<?php
// Script pour configurer la base de données pour la fonctionnalité conducteur-véhicule

require_once __DIR__ . '/api/config/database.php';

try {
    $database = new Database();
    $pdo = $database->getConnection();
    
    echo "=== CONFIGURATION BASE DE DONNÉES CONDUCTEUR-VÉHICULE ===\n\n";
    
    // 1. Vérifier si la table conducteur_vehicule existe
    echo "1. Vérification de la table conducteur_vehicule...\n";
    $stmt = $pdo->query("SHOW TABLES LIKE 'conducteur_vehicule'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Table conducteur_vehicule n'existe pas. Veuillez importer le fichier SQL.\n";
        echo "Commande: mysql -u root -p control_routier < api/database/conducteur_vehicule.sql\n\n";
    } else {
        echo "✅ Table conducteur_vehicule existe\n\n";
    }
    
    // 2. Vérifier si la colonne conducteur_id existe dans vehicule_plaque
    echo "2. Vérification de la colonne conducteur_id dans vehicule_plaque...\n";
    $stmt = $pdo->query("SHOW COLUMNS FROM vehicule_plaque LIKE 'conducteur_id'");
    if ($stmt->rowCount() == 0) {
        echo "⚠️  Colonne conducteur_id n'existe pas. Ajout en cours...\n";
        
        // Ajouter la colonne conducteur_id
        $pdo->exec("ALTER TABLE `vehicule_plaque` ADD COLUMN `conducteur_id` bigint(20) DEFAULT NULL AFTER `updated_at`");
        echo "✅ Colonne conducteur_id ajoutée\n";
        
        // Vérifier si la colonne proprietaire existe déjà
        $stmt = $pdo->query("SHOW COLUMNS FROM vehicule_plaque LIKE 'proprietaire'");
        if ($stmt->rowCount() == 0) {
            $pdo->exec("ALTER TABLE `vehicule_plaque` ADD COLUMN `proprietaire` varchar(200) DEFAULT NULL AFTER `conducteur_id`");
            echo "✅ Colonne proprietaire ajoutée\n";
        }
        
        // Ajouter l'index
        try {
            $pdo->exec("CREATE INDEX `idx_vehicule_conducteur` ON `vehicule_plaque`(`conducteur_id`)");
            echo "✅ Index idx_vehicule_conducteur créé\n";
        } catch (Exception $e) {
            if (strpos($e->getMessage(), 'Duplicate key name') !== false) {
                echo "ℹ️  Index idx_vehicule_conducteur existe déjà\n";
            } else {
                echo "⚠️  Erreur lors de la création de l'index: " . $e->getMessage() . "\n";
            }
        }
        
    } else {
        echo "✅ Colonne conducteur_id existe déjà\n";
    }
    
    // 3. Créer les dossiers d'upload nécessaires
    echo "\n3. Création des dossiers d'upload...\n";
    $uploadDirs = [
        __DIR__ . '/api/uploads/conducteurs',
        __DIR__ . '/api/uploads/contraventions'
    ];
    
    foreach ($uploadDirs as $dir) {
        if (!is_dir($dir)) {
            if (mkdir($dir, 0755, true)) {
                echo "✅ Dossier créé: $dir\n";
            } else {
                echo "❌ Impossible de créer: $dir\n";
            }
        } else {
            echo "✅ Dossier existe: $dir\n";
        }
    }
    
    // 4. Test de connectivité des contrôleurs
    echo "\n4. Test des contrôleurs...\n";
    
    // Test ConducteurVehiculeController
    if (file_exists(__DIR__ . '/api/controllers/ConducteurVehiculeController.php')) {
        echo "✅ ConducteurVehiculeController.php existe\n";
        
        require_once __DIR__ . '/api/controllers/ConducteurVehiculeController.php';
        try {
            $controller = new ConducteurVehiculeController();
            echo "✅ ConducteurVehiculeController instancié avec succès\n";
        } catch (Exception $e) {
            echo "❌ Erreur d'instanciation: " . $e->getMessage() . "\n";
        }
    } else {
        echo "❌ ConducteurVehiculeController.php manquant\n";
    }
    
    // 5. Vérifier les endpoints dans index.php
    echo "\n5. Vérification des endpoints...\n";
    $indexContent = file_get_contents(__DIR__ . '/api/routes/index.php');
    
    if (strpos($indexContent, '/conducteur-vehicule/create') !== false) {
        echo "✅ Endpoint /conducteur-vehicule/create trouvé\n";
    } else {
        echo "❌ Endpoint /conducteur-vehicule/create manquant\n";
    }
    
    if (strpos($indexContent, '/conducteurs') !== false) {
        echo "✅ Endpoint /conducteurs trouvé\n";
    } else {
        echo "❌ Endpoint /conducteurs manquant\n";
    }
    
    echo "\n=== CONFIGURATION TERMINÉE ===\n";
    echo "La fonctionnalité conducteur-véhicule est prête à être utilisée!\n\n";
    
    echo "Pour tester l'API, exécutez:\n";
    echo "php test_conducteur_vehicule_api.php\n\n";
    
} catch (Exception $e) {
    echo "❌ ERREUR: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}
?>
