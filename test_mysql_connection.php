<?php
echo "=== TEST CONNEXION MYSQL ===\n\n";

// Différentes configurations à tester
$configs = [
    ['host' => 'localhost', 'port' => 3306, 'user' => 'root', 'pass' => ''],
    ['host' => '127.0.0.1', 'port' => 3306, 'user' => 'root', 'pass' => ''],
    ['host' => 'localhost', 'port' => 8889, 'user' => 'root', 'pass' => 'root'], // MAMP
    ['host' => '127.0.0.1', 'port' => 8889, 'user' => 'root', 'pass' => 'root'], // MAMP
];

foreach ($configs as $i => $config) {
    echo ($i + 1) . ". Test connexion {$config['host']}:{$config['port']} avec {$config['user']}\n";
    
    try {
        $dsn = "mysql:host={$config['host']};port={$config['port']}";
        $pdo = new PDO($dsn, $config['user'], $config['pass']);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        echo "   ✅ Connexion réussie !\n";
        
        // Vérifier si la base control_routier existe
        $stmt = $pdo->query("SHOW DATABASES LIKE 'control_routier'");
        if ($stmt->rowCount() > 0) {
            echo "   ✅ Base de données 'control_routier' trouvée\n";
            
            // Se connecter à la base
            $pdo->exec("USE control_routier");
            
            // Vérifier les tables
            $stmt = $pdo->query("SHOW TABLES");
            $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
            echo "   📋 Tables trouvées: " . implode(', ', $tables) . "\n";
            
            // Vérifier si permis_temporaire existe
            if (in_array('permis_temporaire', $tables)) {
                echo "   ✅ Table permis_temporaire existe\n";
                
                // Vérifier la structure
                $stmt = $pdo->query("DESCRIBE permis_temporaire");
                $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
                echo "   📋 Colonnes:\n";
                foreach ($columns as $column) {
                    echo "      - {$column['Field']}: {$column['Type']} {$column['Extra']}\n";
                }
            } else {
                echo "   ❌ Table permis_temporaire n'existe pas\n";
            }
            
            // Configuration trouvée, on s'arrête
            echo "\n🎯 Configuration MySQL trouvée: {$config['host']}:{$config['port']}\n";
            echo "Utilisateur: {$config['user']}\n";
            echo "Mot de passe: " . ($config['pass'] ? 'Oui' : 'Vide') . "\n";
            break;
            
        } else {
            echo "   ❌ Base de données 'control_routier' non trouvée\n";
        }
        
    } catch (Exception $e) {
        echo "   ❌ Erreur: " . $e->getMessage() . "\n";
    }
    
    echo "\n";
}

echo "=== FIN TEST ===\n";
?>
