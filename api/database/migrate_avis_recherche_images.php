<?php
/**
 * Script de migration pour ajouter les colonnes images et numero_chassis
 * à la table avis_recherche
 */

require_once __DIR__ . '/../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    echo "Début de la migration...\n\n";
    
    // Vérifier si la colonne images existe déjà
    $checkImages = $db->query("SHOW COLUMNS FROM `avis_recherche` LIKE 'images'");
    if ($checkImages->rowCount() == 0) {
        echo "Ajout de la colonne 'images'...\n";
        $db->exec("ALTER TABLE `avis_recherche` 
                   ADD COLUMN `images` TEXT NULL COMMENT 'Chemins des images au format JSON' 
                   AFTER `niveau`");
        echo "✓ Colonne 'images' ajoutée avec succès\n\n";
    } else {
        echo "✓ Colonne 'images' existe déjà\n\n";
    }
    
    // Vérifier si la colonne numero_chassis existe déjà
    $checkChassis = $db->query("SHOW COLUMNS FROM `avis_recherche` LIKE 'numero_chassis'");
    if ($checkChassis->rowCount() == 0) {
        echo "Ajout de la colonne 'numero_chassis'...\n";
        $db->exec("ALTER TABLE `avis_recherche` 
                   ADD COLUMN `numero_chassis` VARCHAR(100) NULL COMMENT 'Numéro de châssis du véhicule' 
                   AFTER `images`");
        echo "✓ Colonne 'numero_chassis' ajoutée avec succès\n\n";
    } else {
        echo "✓ Colonne 'numero_chassis' existe déjà\n\n";
    }
    
    // Vérifier si l'index existe déjà
    $checkIndex = $db->query("SHOW INDEX FROM `avis_recherche` WHERE Key_name = 'idx_numero_chassis'");
    if ($checkIndex->rowCount() == 0) {
        echo "Ajout de l'index 'idx_numero_chassis'...\n";
        $db->exec("ALTER TABLE `avis_recherche` 
                   ADD KEY `idx_numero_chassis` (`numero_chassis`)");
        echo "✓ Index 'idx_numero_chassis' ajouté avec succès\n\n";
    } else {
        echo "✓ Index 'idx_numero_chassis' existe déjà\n\n";
    }
    
    echo "✅ Migration terminée avec succès!\n";
    echo "\nLa table avis_recherche a été mise à jour avec:\n";
    echo "  - Colonne 'images' (TEXT NULL)\n";
    echo "  - Colonne 'numero_chassis' (VARCHAR(100) NULL)\n";
    echo "  - Index sur 'numero_chassis'\n";
    
} catch (Exception $e) {
    echo "❌ Erreur lors de la migration: " . $e->getMessage() . "\n";
    exit(1);
}
?>
