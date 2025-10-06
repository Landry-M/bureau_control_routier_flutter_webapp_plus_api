<?php
require_once __DIR__ . '/../config/database.php';

try {
    $database = new Database();
    $pdo = $database->getConnection();
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== STRUCTURE DE LA TABLE PARTICULIERS ===\n";
    $stmt = $pdo->query("DESCRIBE particuliers");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $column) {
        echo "- {$column['Field']}: {$column['Type']} " . 
             ($column['Null'] === 'NO' ? '(NOT NULL)' : '(NULL)') . 
             ($column['Key'] ? " [{$column['Key']}]" : '') . "\n";
    }
    
    echo "\n=== STRUCTURE DE LA TABLE VEHICULE_PLAQUE ===\n";
    $stmt = $pdo->query("DESCRIBE vehicule_plaque");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $column) {
        echo "- {$column['Field']}: {$column['Type']} " . 
             ($column['Null'] === 'NO' ? '(NOT NULL)' : '(NULL)') . 
             ($column['Key'] ? " [{$column['Key']}]" : '') . "\n";
    }
    
    echo "\n=== STRUCTURE DE LA TABLE CONDUCTEUR_VEHICULE ===\n";
    $stmt = $pdo->query("DESCRIBE conducteur_vehicule");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $column) {
        echo "- {$column['Field']}: {$column['Type']} " . 
             ($column['Null'] === 'NO' ? '(NOT NULL)' : '(NULL)') . 
             ($column['Key'] ? " [{$column['Key']}]" : '') . "\n";
    }
    
} catch (PDOException $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
}
?>
