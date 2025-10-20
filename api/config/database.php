<?php
require_once __DIR__ . '/env.php';
require_once __DIR__ . '/timezone.php';

// Database configuration
class Database {
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
        try {
            // Configuration DSN selon l'environnement
            if (Environment::getEnvironment() === 'production') {
                // En production, utiliser une seule méthode de connexion
                $dsn_options = [
                    "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=" . $this->charset
                ];
            } else {
                // En développement, essayer différentes méthodes pour macOS
                $dsn_options = [
                    "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=" . $this->charset,
                    "mysql:unix_socket=/tmp/mysql.sock;dbname=" . $this->db_name . ";charset=" . $this->charset,
                    "mysql:host=127.0.0.1;port=3306;dbname=" . $this->db_name . ";charset=" . $this->charset
                ];
            }
            
            foreach ($dsn_options as $dsn) {
                try {
                    // Options PDO pour éviter "MySQL server has gone away"
                    $pdo_options = [
                        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                        PDO::ATTR_PERSISTENT => false, // Éviter les connexions persistantes qui peuvent expirer
                        PDO::ATTR_EMULATE_PREPARES => false,
                        PDO::ATTR_TIMEOUT => 60, // Timeout de connexion à 60 secondes
                        PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
                    ];
                    
                    $this->conn = new PDO($dsn, $this->username, $this->password, $pdo_options);
                    
                    // Configuration supplémentaire après connexion (avec gestion d'erreurs)
                    try {
                        $this->conn->exec("SET SESSION wait_timeout=300");
                        $this->conn->exec("SET SESSION interactive_timeout=300");
                        // Ne pas tenter de modifier max_allowed_packet en SESSION (nécessite GLOBAL)
                    } catch (PDOException $e) {
                        // Ignorer les erreurs de configuration non-critiques
                        error_log("Avertissement configuration MySQL: " . $e->getMessage());
                    }
                    
                    break; // Connection successful
                } catch(PDOException $e) {
                    // Try next DSN option
                    continue;
                }
            }
            
            if (!$this->conn) {
                $error_msg = "Could not connect to MySQL with any method. Environment: " . Environment::getEnvironment();
                if (Environment::isDebugMode()) {
                    $error_msg .= " | Host: " . $this->host . " | DB: " . $this->db_name . " | User: " . $this->username;
                }
                throw new PDOException($error_msg);
            }
            
        } catch(PDOException $exception) {
            $error_msg = "Connection error: " . $exception->getMessage();
            
            // Logger l'erreur dans tous les cas (pas d'echo pour éviter de polluer le JSON)
            error_log("Database connection error: " . $exception->getMessage());
            
            // En mode debug, inclure plus de détails dans l'exception
            if (Environment::isDebugMode()) {
                throw new Exception("Database connection failed: " . $exception->getMessage());
            } else {
                // En production, message générique
                throw new Exception("Database connection failed");
            }
        }
        return $this->conn;
    }
    
    /**
     * Vérifie si la connexion est toujours active, sinon reconnecte
     */
    public function ensureConnection() {
        try {
            // Tester la connexion avec une requête simple
            if ($this->conn) {
                $this->conn->query('SELECT 1');
            } else {
                $this->getConnection();
            }
        } catch (PDOException $e) {
            // La connexion a été perdue, reconnecter
            error_log("MySQL connection lost, reconnecting: " . $e->getMessage());
            $this->conn = null;
            $this->getConnection();
        }
        return $this->conn;
    }
    
    /**
     * Ping la connexion MySQL pour éviter les timeouts
     */
    public function ping() {
        try {
            if ($this->conn) {
                $this->conn->query('SELECT 1');
                return true;
            }
        } catch (PDOException $e) {
            return false;
        }
        return false;
    }
}
?>
