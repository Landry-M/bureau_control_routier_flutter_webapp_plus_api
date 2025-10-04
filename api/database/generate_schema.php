<?php
require_once __DIR__ . '/../config/database.php';

/**
 * Script pour générer la documentation complète de la base de données
 * Exécuter ce script chaque fois que la structure change
 */

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        die("Erreur de connexion à la base de données\n");
    }
    
    echo "=== STRUCTURE DE LA BASE DE DONNÉES BCR ===\n\n";
    
    // Obtenir toutes les tables
    $stmt = $db->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    $schemaDoc = "# Structure de la base de données BCR\n\n";
    $schemaDoc .= "Généré automatiquement le " . date('Y-m-d H:i:s') . "\n\n";
    
    foreach ($tables as $table) {
        echo "Table: $table\n";
        $schemaDoc .= "## Table: `$table`\n\n";
        
        // Obtenir la structure de la table
        $stmt = $db->query("DESCRIBE $table");
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $schemaDoc .= "| Colonne | Type | Null | Clé | Défaut | Extra |\n";
        $schemaDoc .= "|---------|------|------|-----|-----------|-------|\n";
        
        foreach ($columns as $column) {
            echo "  - {$column['Field']} ({$column['Type']})\n";
            $schemaDoc .= "| `{$column['Field']}` | {$column['Type']} | {$column['Null']} | {$column['Key']} | {$column['Default']} | {$column['Extra']} |\n";
        }
        
        $schemaDoc .= "\n";
        
        // Obtenir un exemple de données (5 premiers enregistrements)
        try {
            $stmt = $db->query("SELECT * FROM $table LIMIT 5");
            $samples = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            if (!empty($samples)) {
                $schemaDoc .= "### Exemples de données:\n\n";
                $schemaDoc .= "```json\n";
                $schemaDoc .= json_encode($samples, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
                $schemaDoc .= "\n```\n\n";
            }
        } catch (Exception $e) {
            $schemaDoc .= "### Aucun exemple disponible\n\n";
        }
        
        echo "\n";
    }
    
    // Sauvegarder dans un fichier
    file_put_contents(__DIR__ . '/schema_documentation.md', $schemaDoc);
    
    // Générer aussi un fichier JSON pour l'API
    $schemaJson = [];
    foreach ($tables as $table) {
        $stmt = $db->query("DESCRIBE $table");
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $schemaJson[$table] = [
            'columns' => [],
            'primary_key' => null,
            'indexes' => []
        ];
        
        foreach ($columns as $column) {
            $schemaJson[$table]['columns'][$column['Field']] = [
                'type' => $column['Type'],
                'nullable' => $column['Null'] === 'YES',
                'default' => $column['Default'],
                'extra' => $column['Extra']
            ];
            
            if ($column['Key'] === 'PRI') {
                $schemaJson[$table]['primary_key'] = $column['Field'];
            }
        }
        
        // Obtenir les index
        $stmt = $db->query("SHOW INDEX FROM $table");
        $indexes = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($indexes as $index) {
            if (!isset($schemaJson[$table]['indexes'][$index['Key_name']])) {
                $schemaJson[$table]['indexes'][$index['Key_name']] = [];
            }
            $schemaJson[$table]['indexes'][$index['Key_name']][] = $index['Column_name'];
        }
    }
    
    file_put_contents(__DIR__ . '/schema.json', json_encode($schemaJson, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    
    echo "Documentation générée dans:\n";
    echo "- schema_documentation.md (format lisible)\n";
    echo "- schema.json (format API)\n\n";
    
    echo "=== RÉSUMÉ ===\n";
    echo "Nombre de tables: " . count($tables) . "\n";
    echo "Tables trouvées: " . implode(', ', $tables) . "\n";
    
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
}
?>
