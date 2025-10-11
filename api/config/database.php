<?php
require_once __DIR__ . '/env.php';

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
                    $this->conn = new PDO($dsn, $this->username, $this->password);
                    $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
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
            
            // En mode debug, afficher plus d'informations
            if (Environment::isDebugMode()) {
                echo $error_msg;
            } else {
                // En production, logger l'erreur sans l'afficher
                error_log("Database connection error: " . $exception->getMessage());
                throw new Exception("Database connection failed");
            }
        }
        return $this->conn;
    }
}
?>
