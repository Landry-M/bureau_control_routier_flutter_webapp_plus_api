<?php
/**
 * VERSION DEBUG de Database.php
 * AFFICHE les erreurs réelles au lieu de les cacher
 * ⚠️ À UTILISER UNIQUEMENT POUR LE DIAGNOSTIC
 * ⚠️ NE PAS GARDER EN PRODUCTION
 */

require_once __DIR__ . '/env.php';
require_once __DIR__ . '/timezone.php';

class DatabaseDebug {
    private $host;
    private $db_name;
    private $username;
    private $password;
    private $charset;
    private $conn;
    
    public function __construct() {
        $config = Environment::getDatabaseConfig();
        $this->host = $config['host'];
        $this->db_name = $config['db_name'];
        $this->username = $config['username'];
        $this->password = $config['password'];
        $this->charset = $config['charset'];
    }

    public function getConnection() {
        $this->conn = null;
        
        echo "\n🔍 DEBUG DÉTAILLÉ DE LA CONNEXION :\n";
        echo "═══════════════════════════════════════════════════════════\n";
        echo "Host     : {$this->host}\n";
        echo "Database : {$this->db_name}\n";
        echo "Username : {$this->username}\n";
        echo "Password : " . str_repeat('*', strlen($this->password)) . " (" . strlen($this->password) . " caractères)\n";
        echo "Charset  : {$this->charset}\n\n";
        
        try {
            // Configuration DSN selon l'environnement
            if (Environment::getEnvironment() === 'production') {
                $dsn_options = [
                    "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=" . $this->charset
                ];
            } else {
                $dsn_options = [
                    "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=" . $this->charset,
                    "mysql:unix_socket=/tmp/mysql.sock;dbname=" . $this->db_name . ";charset=" . $this->charset,
                    "mysql:host=127.0.0.1;port=3306;dbname=" . $this->db_name . ";charset=" . $this->charset
                ];
            }
            
            $lastException = null;
            $attemptNumber = 0;
            
            foreach ($dsn_options as $dsn) {
                $attemptNumber++;
                echo "Tentative $attemptNumber : $dsn\n";
                
                try {
                    // Options PDO
                    $pdo_options = [
                        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                        PDO::ATTR_PERSISTENT => false,
                        PDO::ATTR_EMULATE_PREPARES => false,
                        PDO::ATTR_TIMEOUT => 60,
                        PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4, 
                            wait_timeout=300, 
                            interactive_timeout=300, 
                            max_allowed_packet=67108864"
                    ];
                    
                    $this->conn = new PDO($dsn, $this->username, $this->password, $pdo_options);
                    
                    // Configuration supplémentaire après connexion
                    $this->conn->exec("SET SESSION wait_timeout=300");
                    $this->conn->exec("SET SESSION interactive_timeout=300");
                    $this->conn->exec("SET SESSION max_allowed_packet=67108864");
                    
                    echo "✅ Connexion réussie avec cette méthode !\n\n";
                    break; // Connection successful
                    
                } catch(PDOException $e) {
                    echo "❌ Échec : " . $e->getMessage() . "\n";
                    $lastException = $e;
                    continue;
                }
            }
            
            if (!$this->conn) {
                echo "\n";
                echo "╔════════════════════════════════════════════════════════════╗\n";
                echo "║        TOUTES LES TENTATIVES ONT ÉCHOUÉ                   ║\n";
                echo "╚════════════════════════════════════════════════════════════╝\n\n";
                
                if ($lastException) {
                    echo "📋 DERNIÈRE ERREUR PDO :\n";
                    echo "   Code SQLState : " . $lastException->getCode() . "\n";
                    echo "   Message       : " . $lastException->getMessage() . "\n";
                    echo "   Fichier       : " . $lastException->getFile() . "\n";
                    echo "   Ligne         : " . $lastException->getLine() . "\n\n";
                    
                    $errorMsg = strtolower($lastException->getMessage());
                    
                    echo "🔍 ANALYSE DE L'ERREUR :\n";
                    echo "═══════════════════════════════════════════════════════════\n\n";
                    
                    if (strpos($errorMsg, 'access denied') !== false) {
                        echo "❌ PROBLÈME D'AUTHENTIFICATION\n\n";
                        echo "Les identifiants sont refusés par MySQL.\n\n";
                        echo "Actions à prendre :\n";
                        echo "1. Vérifiez dans cPanel > MySQL Databases :\n";
                        echo "   • L'utilisateur existe : {$this->username}\n";
                        echo "   • Le mot de passe est correct\n\n";
                        echo "2. Testez le mot de passe caractère par caractère :\n";
                        echo "   Mot de passe actuel : '{$this->password}'\n";
                        echo "   Longueur : " . strlen($this->password) . " caractères\n\n";
                        echo "3. Recréez le mot de passe si nécessaire\n\n";
                    }
                    
                    if (strpos($errorMsg, 'unknown database') !== false) {
                        echo "❌ BASE DE DONNÉES INTROUVABLE\n\n";
                        echo "La base '{$this->db_name}' n'existe pas.\n\n";
                        echo "Actions à prendre :\n";
                        echo "1. Créez la base dans cPanel > MySQL Databases\n";
                        echo "2. Nom exact à utiliser : {$this->db_name}\n";
                        echo "3. Vérifiez l'orthographe (sensible à la casse)\n\n";
                    }
                    
                    if (strpos($errorMsg, "can't connect") !== false || strpos($errorMsg, 'connection refused') !== false) {
                        echo "❌ SERVEUR MySQL INACCESSIBLE\n\n";
                        echo "Le serveur '{$this->host}' ne répond pas.\n\n";
                        echo "Actions à prendre :\n";
                        echo "1. Essayez '127.0.0.1' au lieu de 'localhost'\n";
                        echo "2. Contactez votre hébergeur pour le bon host MySQL\n";
                        echo "3. Vérifiez que MySQL est démarré\n\n";
                    }
                }
                
                throw $lastException;
            }
            
        } catch(PDOException $exception) {
            echo "\n❌ EXCEPTION PDO CAPTURÉE\n";
            echo "Message complet : " . $exception->getMessage() . "\n";
            throw $exception; // Relancer pour que le script appelant la voie
        }
        
        return $this->conn;
    }
}
?>
