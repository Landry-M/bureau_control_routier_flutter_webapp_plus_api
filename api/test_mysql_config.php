<?php
/**
 * Script de test pour vérifier la configuration MySQL
 * et diagnostiquer les problèmes "MySQL server has gone away"
 */

header('Content-Type: text/plain; charset=UTF-8');

echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║     DIAGNOSTIC MYSQL - Configuration et Connexion         ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

require_once __DIR__ . '/config/database.php';

try {
    echo "📡 Connexion à MySQL...\n";
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        echo "❌ Échec de connexion\n";
        exit(1);
    }
    
    echo "✅ Connexion réussie\n\n";
    
    // Test 1: Configuration de session
    echo "═══════════════════════════════════════════════════════════\n";
    echo "📋 CONFIGURATION SESSION (Valeurs appliquées)\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $configs = [
        'wait_timeout' => [
            'query' => "SELECT @@session.wait_timeout",
            'unit' => 'secondes',
            'expected' => 300,
            'description' => 'Timeout inactivité'
        ],
        'interactive_timeout' => [
            'query' => "SELECT @@session.interactive_timeout",
            'unit' => 'secondes',
            'expected' => 300,
            'description' => 'Timeout interactif'
        ],
        'max_allowed_packet' => [
            'query' => "SELECT @@session.max_allowed_packet",
            'unit' => 'MB',
            'expected' => 67108864,
            'description' => 'Taille max paquet'
        ],
        'net_read_timeout' => [
            'query' => "SELECT @@session.net_read_timeout",
            'unit' => 'secondes',
            'expected' => 60,
            'description' => 'Timeout lecture'
        ],
        'net_write_timeout' => [
            'query' => "SELECT @@session.net_write_timeout",
            'unit' => 'secondes',
            'expected' => 60,
            'description' => 'Timeout écriture'
        ]
    ];
    
    $allGood = true;
    
    foreach ($configs as $name => $config) {
        $result = $db->query($config['query'])->fetchColumn();
        
        // Formater la valeur
        if ($config['unit'] === 'MB') {
            $displayValue = round($result / 1024 / 1024, 2) . ' MB';
            $isGood = $result >= $config['expected'];
        } else {
            $displayValue = $result . ' ' . $config['unit'];
            $isGood = $result >= $config['expected'];
        }
        
        $status = $isGood ? '✅' : '⚠️ ';
        $allGood = $allGood && $isGood;
        
        printf("%-25s : %s %s\n", $config['description'], $status, $displayValue);
        
        if (!$isGood) {
            printf("   → Recommandé : >= %s %s\n", 
                $config['unit'] === 'MB' 
                    ? round($config['expected'] / 1024 / 1024, 2) . ' MB'
                    : $config['expected'] . ' ' . $config['unit']
            );
        }
    }
    
    echo "\n";
    
    // Test 2: Configuration globale (serveur)
    echo "═══════════════════════════════════════════════════════════\n";
    echo "🌐 CONFIGURATION GLOBALE (Serveur MySQL)\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $globalConfigs = [
        'max_connections' => "SELECT @@global.max_connections",
        'max_allowed_packet' => "SELECT @@global.max_allowed_packet"
    ];
    
    foreach ($globalConfigs as $name => $query) {
        $result = $db->query($query)->fetchColumn();
        
        if ($name === 'max_allowed_packet') {
            $displayValue = round($result / 1024 / 1024, 2) . ' MB';
        } else {
            $displayValue = $result;
        }
        
        printf("%-25s : %s\n", ucfirst(str_replace('_', ' ', $name)), $displayValue);
    }
    
    echo "\n";
    
    // Test 3: Test de ping
    echo "═══════════════════════════════════════════════════════════\n";
    echo "🏓 TEST PING (Vérification connexion active)\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $pingResult = $database->ping();
    if ($pingResult) {
        echo "✅ Connexion active - Ping réussi\n";
    } else {
        echo "❌ Connexion perdue - Ping échoué\n";
        $allGood = false;
    }
    
    echo "\n";
    
    // Test 4: Informations serveur
    echo "═══════════════════════════════════════════════════════════\n";
    echo "ℹ️  INFORMATIONS SERVEUR\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $serverInfo = [
        'Version MySQL' => "SELECT VERSION()",
        'Charset serveur' => "SELECT @@character_set_server",
        'Collation' => "SELECT @@collation_server",
        'Uptime' => "SELECT @@global.uptime"
    ];
    
    foreach ($serverInfo as $label => $query) {
        $result = $db->query($query)->fetchColumn();
        
        if ($label === 'Uptime') {
            $hours = floor($result / 3600);
            $minutes = floor(($result % 3600) / 60);
            $displayValue = "{$hours}h {$minutes}m";
        } else {
            $displayValue = $result;
        }
        
        printf("%-20s : %s\n", $label, $displayValue);
    }
    
    echo "\n";
    
    // Test 5: Test d'upload simulé
    echo "═══════════════════════════════════════════════════════════\n";
    echo "📤 TEST UPLOAD SIMULÉ (Paquet volumineux)\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    try {
        // Créer une chaîne de 10 MB pour simuler un upload
        $largeData = str_repeat('x', 10 * 1024 * 1024);
        $testQuery = "SELECT LENGTH(:data) as size";
        $stmt = $db->prepare($testQuery);
        $stmt->bindParam(':data', $largeData, PDO::PARAM_STR);
        $stmt->execute();
        $size = $stmt->fetchColumn();
        
        echo "✅ Upload simulé réussi (10 MB)\n";
        echo "   Taille reçue : " . round($size / 1024 / 1024, 2) . " MB\n";
    } catch (Exception $e) {
        echo "⚠️  Upload simulé échoué\n";
        echo "   Erreur : " . $e->getMessage() . "\n";
        echo "   → Augmenter max_allowed_packet\n";
        $allGood = false;
    }
    
    echo "\n";
    
    // Résumé final
    echo "═══════════════════════════════════════════════════════════\n";
    echo "📊 RÉSUMÉ\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    if ($allGood) {
        echo "✅ Toutes les vérifications sont PASSÉES\n";
        echo "   Votre configuration MySQL est optimale.\n";
        echo "   Vous ne devriez plus avoir \"MySQL server has gone away\"\n";
    } else {
        echo "⚠️  Certaines vérifications ont ÉCHOUÉ\n";
        echo "   Actions recommandées :\n\n";
        echo "   1. Exécuter le script SQL de configuration :\n";
        echo "      /api/config/mysql_server_config.sql\n\n";
        echo "   2. Ou contacter votre hébergeur pour augmenter :\n";
        echo "      - max_allowed_packet à 64 MB\n";
        echo "      - wait_timeout à 300 secondes\n\n";
        echo "   3. Vérifier les logs MySQL pour plus d'infos\n";
    }
    
    echo "\n";
    echo "═══════════════════════════════════════════════════════════\n";
    echo "📝 NOTES\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    echo "• Ce test vérifie la configuration de SESSION uniquement\n";
    echo "• Les valeurs sont appliquées automatiquement par PDO\n";
    echo "• Pour une configuration permanente, modifier my.cnf\n";
    echo "• Documentation : SOLUTION_MYSQL_SERVER_GONE_AWAY.md\n";
    
    echo "\n";
    
} catch (Exception $e) {
    echo "\n❌ ERREUR FATALE\n\n";
    echo "Message : " . $e->getMessage() . "\n";
    echo "Fichier : " . $e->getFile() . "\n";
    echo "Ligne   : " . $e->getLine() . "\n\n";
    echo "Vérifiez votre configuration dans /api/config/database.php\n";
    exit(1);
}

echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║                      FIN DU DIAGNOSTIC                     ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n";
?>
