<?php
require_once __DIR__ . '/../config/database.php';

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    if (!$conn) {
        die("❌ Connexion échouée\n");
    }
    
    echo "=== Structure de la table accidents ===\n\n";
    
    // Vérifier si la table existe
    $result = $conn->query("SHOW TABLES LIKE 'accidents'");
    if ($result->rowCount() == 0) {
        echo "❌ La table 'accidents' n'existe pas!\n";
        echo "Création de la table accidents...\n\n";
        
        // Créer la table accidents
        $sql = "CREATE TABLE IF NOT EXISTS accidents (
            id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            date_accident DATETIME NOT NULL,
            lieu VARCHAR(255) NOT NULL,
            gravite ENUM('materiel', 'corporel', 'mortel') DEFAULT 'materiel',
            description TEXT,
            images TEXT NULL COMMENT 'JSON array ou CSV des chemins',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_date_accident (date_accident),
            INDEX idx_gravite (gravite)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
        
        $conn->exec($sql);
        echo "✓ Table accidents créée\n\n";
    }
    
    // Afficher la structure
    $stmt = $conn->query("DESCRIBE accidents");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Colonnes de la table accidents:\n";
    echo str_repeat("-", 80) . "\n";
    printf("%-20s %-30s %-10s %-10s\n", "Field", "Type", "Null", "Key");
    echo str_repeat("-", 80) . "\n";
    
    foreach ($columns as $col) {
        printf("%-20s %-30s %-10s %-10s\n", 
            $col['Field'], 
            $col['Type'], 
            $col['Null'], 
            $col['Key']
        );
    }
    
    echo "\n";
    
    // Vérifier le type de la colonne id
    $idColumn = array_filter($columns, function($col) {
        return $col['Field'] === 'id';
    });
    
    if (!empty($idColumn)) {
        $idColumn = array_values($idColumn)[0];
        echo "✓ Type de la colonne id: " . $idColumn['Type'] . "\n";
        echo "✓ Clé: " . $idColumn['Key'] . "\n";
        
        if ($idColumn['Key'] !== 'PRI') {
            echo "⚠️  ATTENTION: id n'est pas une clé primaire!\n";
        }
    }
    
    // Vérifier la table temoins
    echo "\n=== Structure de la table temoins ===\n\n";
    $result = $conn->query("SHOW TABLES LIKE 'temoins'");
    if ($result->rowCount() == 0) {
        echo "❌ La table 'temoins' n'existe pas!\n";
        echo "Création de la table temoins...\n\n";
        
        $sql = "CREATE TABLE IF NOT EXISTS temoins (
            id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            id_accident INT(10) UNSIGNED NOT NULL,
            nom VARCHAR(255) NOT NULL,
            telephone VARCHAR(20),
            age INT,
            lien_avec_accident VARCHAR(100),
            temoignage TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (id_accident) REFERENCES accidents(id) ON DELETE CASCADE,
            INDEX idx_accident (id_accident)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
        
        $conn->exec($sql);
        echo "✓ Table temoins créée\n";
    } else {
        echo "✓ La table temoins existe\n";
    }
    
    // Vérifier la table vehicule_plaque
    echo "\n=== Vérification table vehicule_plaque ===\n";
    $result = $conn->query("SHOW TABLES LIKE 'vehicule_plaque'");
    if ($result->rowCount() > 0) {
        echo "✓ La table vehicule_plaque existe\n";
        
        // Vérifier le type de la colonne id
        $stmt = $conn->query("DESCRIBE vehicule_plaque");
        $vpColumns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $vpIdColumn = array_filter($vpColumns, function($col) {
            return $col['Field'] === 'id';
        });
        
        if (!empty($vpIdColumn)) {
            $vpIdColumn = array_values($vpIdColumn)[0];
            echo "  Type de id: " . $vpIdColumn['Type'] . "\n";
        }
    } else {
        echo "❌ La table vehicule_plaque n'existe pas!\n";
    }
    
    echo "\n=== Recommandation ===\n";
    echo "Pour créer parties_impliquees, les tables suivantes doivent exister:\n";
    echo "  1. accidents avec id INT(10) UNSIGNED PRIMARY KEY\n";
    echo "  2. vehicule_plaque avec id INT(10) UNSIGNED PRIMARY KEY\n";
    echo "\n";
    
} catch (Exception $e) {
    echo "❌ ERREUR: " . $e->getMessage() . "\n";
}
?>
