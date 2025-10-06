<?php
// Script pour corriger la contrainte NOT NULL sur la colonne photo

require_once __DIR__ . '/api/config/database.php';

try {
    $database = new Database();
    $pdo = $database->getConnection();
    
    echo "=== CORRECTION CONTRAINTE PHOTO ===\n\n";
    
    // Modifier la colonne photo pour permettre NULL
    echo "Modification de la colonne photo pour permettre NULL...\n";
    $pdo->exec("ALTER TABLE conducteur_vehicule MODIFY COLUMN photo longtext DEFAULT NULL");
    echo "✅ Colonne photo modifiée avec succès\n\n";
    
    // Vérifier la modification
    $stmt = $pdo->query("DESCRIBE conducteur_vehicule");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($columns as $column) {
        if ($column['Field'] === 'photo') {
            echo "Statut de la colonne photo:\n";
            echo "- Type: " . $column['Type'] . "\n";
            echo "- Null: " . $column['Null'] . "\n";
            echo "- Default: " . ($column['Default'] ?? 'NULL') . "\n";
            break;
        }
    }
    
    echo "\n✅ Correction terminée!\n";
    
} catch (Exception $e) {
    echo "❌ ERREUR: " . $e->getMessage() . "\n";
}
?>
