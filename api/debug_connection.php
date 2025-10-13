<?php
/**
 * Script de DEBUG pour afficher l'erreur exacte de connexion MySQL
 * ⚠️ À SUPPRIMER après avoir résolu le problème !
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain; charset=UTF-8');

echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║      DEBUG CONNEXION - AFFICHAGE DES ERREURS DÉTAILLÉES   ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

// Charger l'environnement
require_once __DIR__ . '/config/env.php';

$config = Environment::getDatabaseConfig();
$env = Environment::getEnvironment();

echo "🌐 Environnement détecté : $env\n";
echo "🔧 Configuration utilisée :\n";
echo "   Host     : {$config['host']}\n";
echo "   Database : {$config['db_name']}\n";
echo "   Username : {$config['username']}\n";
echo "   Password : " . (strlen($config['password']) > 0 ? str_repeat('*', strlen($config['password'])) : 'VIDE') . "\n\n";

echo "═══════════════════════════════════════════════════════════\n";
echo "TEST 1 : Connexion PDO directe\n";
echo "═══════════════════════════════════════════════════════════\n\n";

// Test 1 : Connexion basique
$dsn = "mysql:host={$config['host']};charset={$config['charset']}";

try {
    echo "➤ Connexion au serveur MySQL (sans spécifier de base)...\n";
    $pdo = new PDO($dsn, $config['username'], $config['password']);
    echo "   ✅ Connexion au serveur MySQL réussie !\n\n";
    
    // Lister les bases de données accessibles
    echo "➤ Bases de données accessibles :\n";
    $databases = $pdo->query("SHOW DATABASES")->fetchAll(PDO::FETCH_COLUMN);
    foreach ($databases as $db) {
        echo "   • $db" . ($db === $config['db_name'] ? " ← CIBLE" : "") . "\n";
    }
    echo "\n";
    
    // Vérifier si la base cible existe
    if (in_array($config['db_name'], $databases)) {
        echo "   ✅ La base '{$config['db_name']}' existe\n\n";
    } else {
        echo "   ❌ La base '{$config['db_name']}' N'EXISTE PAS\n\n";
        echo "📝 SOLUTION :\n";
        echo "   1. Créer la base dans cPanel : MySQL Databases\n";
        echo "   2. Ou corriger le nom dans /api/config/env.php\n\n";
        exit(1);
    }
    
} catch (PDOException $e) {
    echo "   ❌ ÉCHEC de connexion au serveur MySQL\n\n";
    echo "📋 ERREUR DÉTAILLÉE :\n";
    echo "   Code    : " . $e->getCode() . "\n";
    echo "   Message : " . $e->getMessage() . "\n";
    echo "   Fichier : " . $e->getFile() . "\n";
    echo "   Ligne   : " . $e->getLine() . "\n\n";
    
    echo "🔍 DIAGNOSTIC :\n";
    
    if (strpos($e->getMessage(), 'Access denied') !== false) {
        echo "   ❌ IDENTIFIANTS INCORRECTS\n\n";
        echo "   Vérifications :\n";
        echo "   • Nom d'utilisateur : '{$config['username']}'\n";
        echo "   • Mot de passe a " . strlen($config['password']) . " caractères\n";
        echo "   • Premier caractère du mot de passe : '" . substr($config['password'], 0, 1) . "'\n";
        echo "   • Dernier caractère du mot de passe : '" . substr($config['password'], -1) . "'\n\n";
        echo "   Actions :\n";
        echo "   1. Vérifiez dans cPanel : MySQL Databases\n";
        echo "   2. Recréez le mot de passe si nécessaire\n";
        echo "   3. Vérifiez qu'il n'y a pas d'espaces au début/fin\n";
    }
    
    if (strpos($e->getMessage(), "Can't connect") !== false) {
        echo "   ❌ SERVEUR MySQL INACCESSIBLE\n\n";
        echo "   Le host '{$config['host']}' ne répond pas.\n\n";
        echo "   Essayez dans env.php :\n";
        echo "   'host' => '127.0.0.1',\n";
        echo "   ou\n";
        echo "   'host' => 'nom_serveur_mysql',\n\n";
    }
    
    exit(1);
}

echo "═══════════════════════════════════════════════════════════\n";
echo "TEST 2 : Connexion avec base de données spécifiée\n";
echo "═══════════════════════════════════════════════════════════\n\n";

$dsnWithDb = "mysql:host={$config['host']};dbname={$config['db_name']};charset={$config['charset']}";

try {
    echo "➤ Connexion à la base '{$config['db_name']}'...\n";
    $pdo2 = new PDO($dsnWithDb, $config['username'], $config['password']);
    $pdo2->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "   ✅ Connexion avec base de données réussie !\n\n";
    
    // Test de requête
    echo "➤ Test de requête SELECT...\n";
    $version = $pdo2->query("SELECT VERSION()")->fetchColumn();
    echo "   MySQL Version : $version\n\n";
    
    // Lister quelques tables
    echo "➤ Tables dans la base de données :\n";
    $tables = $pdo2->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
    
    if (count($tables) > 0) {
        echo "   Total : " . count($tables) . " tables\n";
        foreach (array_slice($tables, 0, 10) as $table) {
            echo "   • $table\n";
        }
        if (count($tables) > 10) {
            echo "   • ... et " . (count($tables) - 10) . " autres\n";
        }
    } else {
        echo "   ⚠️  Base de données vide (aucune table)\n";
        echo "   Importez le schéma SQL depuis /api/database/\n";
    }
    
} catch (PDOException $e) {
    echo "   ❌ ÉCHEC de connexion à la base de données\n\n";
    echo "📋 ERREUR DÉTAILLÉE :\n";
    echo "   Code    : " . $e->getCode() . "\n";
    echo "   Message : " . $e->getMessage() . "\n\n";
    
    if (strpos($e->getMessage(), 'Access denied') !== false) {
        echo "🔍 DIAGNOSTIC :\n";
        echo "   L'utilisateur peut se connecter mais n'a pas les privilèges\n";
        echo "   sur la base '{$config['db_name']}'\n\n";
        echo "📝 SOLUTION :\n";
        echo "   1. Aller dans cPanel : MySQL Databases\n";
        echo "   2. Section : Add User To Database\n";
        echo "   3. Utilisateur : {$config['username']}\n";
        echo "   4. Base : {$config['db_name']}\n";
        echo "   5. Cocher ALL PRIVILEGES\n";
    }
    
    exit(1);
}

echo "\n";
echo "═══════════════════════════════════════════════════════════\n";
echo "TEST 3 : Classe Database de l'application\n";
echo "═══════════════════════════════════════════════════════════\n\n";

try {
    echo "➤ Chargement de la classe Database...\n";
    require_once __DIR__ . '/config/database.php';
    
    echo "➤ Création d'une instance Database...\n";
    $database = new Database();
    
    echo "➤ Appel getConnection()...\n";
    $db = $database->getConnection();
    
    if ($db) {
        echo "   ✅ Connexion via classe Database réussie !\n\n";
        
        // Test ping
        echo "➤ Test ping...\n";
        if ($database->ping()) {
            echo "   ✅ Ping MySQL : OK\n";
        }
    } else {
        echo "   ❌ getConnection() a retourné NULL\n";
    }
    
} catch (Exception $e) {
    echo "   ❌ ERREUR avec la classe Database\n\n";
    echo "📋 ERREUR DÉTAILLÉE :\n";
    echo "   Message : " . $e->getMessage() . "\n";
    echo "   Fichier : " . $e->getFile() . "\n";
    echo "   Ligne   : " . $e->getLine() . "\n";
    echo "   Trace   :\n";
    echo "   " . str_replace("\n", "\n   ", $e->getTraceAsString()) . "\n";
    exit(1);
}

echo "\n";
echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║                  ✅ TOUS LES TESTS RÉUSSIS                ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

echo "✨ La connexion MySQL fonctionne parfaitement !\n\n";

echo "Si l'application affiche toujours une erreur :\n";
echo "  1. Videz le cache PHP (opcache)\n";
echo "  2. Redémarrez PHP-FPM si disponible\n";
echo "  3. Vérifiez les permissions des fichiers (644)\n";
echo "  4. Consultez les logs : /var/log/php_errors.log\n\n";

echo "⚠️  IMPORTANT : SUPPRIMEZ ce fichier après diagnostic !\n";
echo "    Ce script affiche des informations sensibles.\n";
echo "    rm " . __FILE__ . "\n";

?>
