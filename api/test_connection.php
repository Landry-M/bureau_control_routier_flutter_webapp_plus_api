<?php
/**
 * Script de diagnostic de connexion MySQL
 * À uploader sur le serveur pour tester la connexion
 */

header('Content-Type: text/plain; charset=UTF-8');

echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║         DIAGNOSTIC CONNEXION BASE DE DONNÉES              ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

// Étape 1 : Vérifier que les fichiers existent
echo "📁 Vérification des fichiers...\n";
echo "───────────────────────────────────────────────────────────\n";

$files = [
    'config/env.php' => __DIR__ . '/config/env.php',
    'config/database.php' => __DIR__ . '/config/database.php',
    'config/timezone.php' => __DIR__ . '/config/timezone.php'
];

$allFilesExist = true;
foreach ($files as $name => $path) {
    if (file_exists($path)) {
        echo "✅ $name existe\n";
    } else {
        echo "❌ $name MANQUANT\n";
        $allFilesExist = false;
    }
}

if (!$allFilesExist) {
    echo "\n⚠️  Fichiers manquants ! Uploadez-les sur le serveur.\n";
    exit(1);
}

echo "\n";

// Étape 2 : Charger et afficher l'environnement
echo "🌐 Détection de l'environnement...\n";
echo "───────────────────────────────────────────────────────────\n";

require_once __DIR__ . '/config/env.php';

$currentHost = $_SERVER['HTTP_HOST'] ?? $_SERVER['SERVER_NAME'] ?? 'INCONNU';
$environment = Environment::getEnvironment();
$isDebug = Environment::isDebugMode();

echo "Host détecté    : $currentHost\n";
echo "Environnement   : $environment\n";
echo "Mode debug      : " . ($isDebug ? 'OUI' : 'NON') . "\n\n";

// Étape 3 : Afficher la configuration (masquer le mot de passe)
echo "⚙️  Configuration base de données...\n";
echo "───────────────────────────────────────────────────────────\n";

$config = Environment::getDatabaseConfig();

echo "Host            : " . $config['host'] . "\n";
echo "Base de données : " . $config['db_name'] . "\n";
echo "Utilisateur     : " . $config['username'] . "\n";
echo "Mot de passe    : " . str_repeat('*', strlen($config['password'])) . " (" . strlen($config['password']) . " caractères)\n";
echo "Charset         : " . $config['charset'] . "\n\n";

// Étape 4 : Test de connexion SIMPLE (sans Database class)
echo "🔌 Test de connexion MySQL (direct PDO)...\n";
echo "───────────────────────────────────────────────────────────\n";

$dsn = "mysql:host={$config['host']};dbname={$config['db_name']};charset={$config['charset']}";

try {
    echo "Tentative de connexion...\n";
    echo "DSN: mysql:host={$config['host']};dbname={$config['db_name']}\n\n";
    
    $pdo = new PDO($dsn, $config['username'], $config['password']);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "✅ CONNEXION RÉUSSIE !\n\n";
    
    // Test de requête
    echo "📊 Test de requête...\n";
    $version = $pdo->query('SELECT VERSION()')->fetchColumn();
    echo "Version MySQL   : $version\n";
    
    $currentDb = $pdo->query('SELECT DATABASE()')->fetchColumn();
    echo "Base actuelle   : $currentDb\n";
    
    $userHost = $pdo->query('SELECT USER()')->fetchColumn();
    echo "Utilisateur     : $userHost\n\n";
    
    // Test des tables
    echo "📋 Vérification des tables...\n";
    $tables = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
    echo "Nombre de tables: " . count($tables) . "\n";
    
    if (count($tables) > 0) {
        echo "Exemples de tables:\n";
        foreach (array_slice($tables, 0, 5) as $table) {
            echo "  • $table\n";
        }
        if (count($tables) > 5) {
            echo "  • ... et " . (count($tables) - 5) . " autres\n";
        }
    } else {
        echo "⚠️  Aucune table trouvée dans la base de données\n";
    }
    
} catch (PDOException $e) {
    echo "❌ ÉCHEC DE CONNEXION\n\n";
    echo "Code d'erreur   : " . $e->getCode() . "\n";
    echo "Message         : " . $e->getMessage() . "\n\n";
    
    echo "🔍 CAUSES POSSIBLES :\n";
    echo "───────────────────────────────────────────────────────────\n";
    
    $errorCode = $e->getCode();
    $errorMsg = strtolower($e->getMessage());
    
    if (strpos($errorMsg, 'access denied') !== false || $errorCode == 1045) {
        echo "❌ IDENTIFIANTS INCORRECTS\n";
        echo "   • Vérifiez le nom d'utilisateur et le mot de passe\n";
        echo "   • Vérifiez dans cPanel : MySQL Databases\n";
        echo "   • Le mot de passe contient-il des caractères spéciaux ?\n\n";
    }
    
    if (strpos($errorMsg, 'unknown database') !== false || $errorCode == 1049) {
        echo "❌ BASE DE DONNÉES INTROUVABLE\n";
        echo "   • La base '{$config['db_name']}' n'existe pas\n";
        echo "   • Créez-la dans cPanel : MySQL Databases\n";
        echo "   • Vérifiez l'orthographe exacte du nom\n\n";
    }
    
    if (strpos($errorMsg, "can't connect") !== false || $errorCode == 2002) {
        echo "❌ SERVEUR MySQL INACCESSIBLE\n";
        echo "   • Le host '{$config['host']}' est incorrect\n";
        echo "   • Essayez 'localhost' ou '127.0.0.1'\n";
        echo "   • Vérifiez si MySQL fonctionne sur le serveur\n\n";
    }
    
    if (strpos($errorMsg, 'too many connections') !== false) {
        echo "❌ TROP DE CONNEXIONS\n";
        echo "   • Le serveur MySQL a atteint sa limite\n";
        echo "   • Attendez quelques minutes et réessayez\n\n";
    }
    
    echo "📝 ACTIONS RECOMMANDÉES :\n";
    echo "   1. Vérifiez vos identifiants dans cPanel\n";
    echo "   2. Assurez-vous que la base de données existe\n";
    echo "   3. Vérifiez que l'utilisateur a les privilèges sur cette base\n";
    echo "   4. Testez le mot de passe (attention aux caractères spéciaux)\n";
    
    exit(1);
}

echo "\n";

// Étape 5 : Test avec la classe Database
echo "🔧 Test avec la classe Database...\n";
echo "───────────────────────────────────────────────────────────\n";

try {
    require_once __DIR__ . '/config/database.php';
    
    $database = new Database();
    $db = $database->getConnection();
    
    if ($db) {
        echo "✅ Connexion via Database class réussie\n\n";
        
        // Test ping
        if ($database->ping()) {
            echo "✅ Ping MySQL : OK\n";
        } else {
            echo "⚠️  Ping MySQL : ÉCHEC\n";
        }
    } else {
        echo "❌ Connexion via Database class échouée\n";
    }
    
} catch (Exception $e) {
    echo "❌ Erreur avec Database class\n";
    echo "Message : " . $e->getMessage() . "\n";
}

echo "\n";

// Résumé final
echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║                    RÉSUMÉ DU DIAGNOSTIC                    ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

echo "✅ La connexion MySQL fonctionne correctement !\n";
echo "   Votre application devrait fonctionner sans problème.\n\n";

echo "📝 Si l'erreur persiste dans l'application :\n";
echo "   1. Videz le cache de l'application\n";
echo "   2. Rechargez la page (Ctrl+F5)\n";
echo "   3. Vérifiez les logs PHP : error_log\n";
echo "   4. Vérifiez que tous les fichiers sont bien uploadés\n\n";

echo "🔐 SÉCURITÉ : Supprimez ce fichier après les tests !\n";
echo "   rm " . __FILE__ . "\n";

?>
