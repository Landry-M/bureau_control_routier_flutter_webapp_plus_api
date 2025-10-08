<?php
// Script pour vérifier la structure de la table contraventions
require_once 'api/config/database.php';

echo "=== Vérification de la structure de la table contraventions ===\n\n";

try {
    $database = new Database();
    $db = $database->getConnection();
    
    // 1. Vérifier l'existence de la table
    echo "1. Vérification de l'existence de la table...\n";
    $checkTable = $db->query("SHOW TABLES LIKE 'contraventions'");
    
    if ($checkTable->rowCount() == 0) {
        echo "❌ La table 'contraventions' n'existe pas\n";
        exit(1);
    }
    
    echo "✅ La table 'contraventions' existe\n\n";
    
    // 2. Afficher la structure de la table
    echo "2. Structure de la table:\n";
    $structure = $db->query("DESCRIBE contraventions");
    $columns = $structure->fetchAll(PDO::FETCH_ASSOC);
    
    $requiredColumns = [
        'id' => false,
        'dossier_id' => false,
        'type_dossier' => false,
        'date_infraction' => false,
        'lieu' => false,
        'type_infraction' => false,
        'description' => false,
        'reference_loi' => false,
        'amende' => false,
        'payed' => false,
        'created_at' => false,
        'photos' => false,
        'pdf_path' => false,
        'latitude' => false,
        'longitude' => false
    ];
    
    echo "Colonnes trouvées:\n";
    foreach ($columns as $column) {
        $name = $column['Field'];
        $type = $column['Type'];
        $null = $column['Null'];
        $default = $column['Default'];
        
        echo "- $name ($type) - NULL: $null - Default: " . ($default ?? 'NULL') . "\n";
        
        if (isset($requiredColumns[$name])) {
            $requiredColumns[$name] = true;
        }
    }
    
    echo "\n3. Vérification des colonnes requises:\n";
    $allPresent = true;
    foreach ($requiredColumns as $column => $present) {
        if ($present) {
            echo "✅ $column\n";
        } else {
            echo "❌ $column (MANQUANTE)\n";
            $allPresent = false;
        }
    }
    
    if ($allPresent) {
        echo "\n✅ Toutes les colonnes requises sont présentes\n";
    } else {
        echo "\n❌ Certaines colonnes sont manquantes\n";
        echo "\nPour ajouter les colonnes manquantes, exécutez:\n";
        echo "- php -f api/database/add_pdf_path_to_contraventions.sql\n";
        echo "- php -f api/database/add_lat_lng_to_contraventions.sql\n";
    }
    
    // 4. Compter les contraventions existantes
    echo "\n4. Statistiques:\n";
    $count = $db->query("SELECT COUNT(*) as total FROM contraventions")->fetch();
    echo "- Total contraventions: " . $count['total'] . "\n";
    
    $withPdf = $db->query("SELECT COUNT(*) as total FROM contraventions WHERE pdf_path IS NOT NULL AND pdf_path != ''")->fetch();
    echo "- Avec PDF: " . $withPdf['total'] . "\n";
    
    $withCoords = $db->query("SELECT COUNT(*) as total FROM contraventions WHERE latitude IS NOT NULL AND longitude IS NOT NULL")->fetch();
    echo "- Avec coordonnées: " . $withCoords['total'] . "\n";
    
    echo "\n=== Vérification terminée ===\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
