<?php
/**
 * Script pour ajouter la colonne pdf_path à la table avis_recherche
 */

require_once __DIR__ . '/../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    echo "Ajout de la colonne pdf_path...\n\n";
    
    // Vérifier si la colonne existe déjà
    $checkColumn = $db->query("SHOW COLUMNS FROM avis_recherche LIKE 'pdf_path'");
    if ($checkColumn->rowCount() == 0) {
        echo "Ajout de la colonne 'pdf_path'...\n";
        $db->exec("ALTER TABLE `avis_recherche` 
                   ADD COLUMN `pdf_path` TEXT NULL 
                   COMMENT 'Chemin du PDF généré pour l''avis de recherche' 
                   AFTER `numero_chassis`");
        echo "✓ Colonne 'pdf_path' ajoutée avec succès\n\n";
    } else {
        echo "✓ Colonne 'pdf_path' existe déjà\n\n";
    }
    
    echo "✅ Migration terminée avec succès!\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    exit(1);
}
?>
