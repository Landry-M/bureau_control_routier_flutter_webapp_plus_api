<?php
require_once __DIR__ . '/api/config/database.php';

echo "=== VÉRIFICATION DE LA STRUCTURE DE LA TABLE ENTREPRISES ===\n\n";

try {
    $database = new Database();
    $pdo = $database->getConnection();
    
    // Vérifier la structure de la table
    $stmt = $pdo->query("DESCRIBE entreprises");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Colonnes de la table 'entreprises':\n";
    foreach ($columns as $column) {
        echo "- " . $column['Field'] . " (" . $column['Type'] . ")\n";
    }
    
    echo "\n=== DONNÉES D'EXEMPLE ===\n";
    $stmt = $pdo->query("SELECT * FROM entreprises LIMIT 1");
    $sample = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($sample) {
        echo "Exemple d'enregistrement:\n";
        foreach ($sample as $key => $value) {
            echo "- $key: " . ($value ?: 'NULL') . "\n";
        }
    } else {
        echo "Aucun enregistrement trouvé.\n";
    }
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}

echo "\n=== FIN DE LA VÉRIFICATION ===\n";
?>
