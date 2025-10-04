<?php
// Database configuration
class Database {
    private $host = 'localhost';
    private $db_name = 'control_routier'; // Change this to your database name
    private $username = 'root';   // Change this to your MySQL username
    private $password = '';       // Change this to your MySQL password
    private $conn;

    public function getConnection() {
        $this->conn = null;
        try {
            // Try different connection methods for macOS
            $dsn_options = [
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8",
                "mysql:unix_socket=/tmp/mysql.sock;dbname=" . $this->db_name . ";charset=utf8",
                "mysql:host=127.0.0.1;port=3306;dbname=" . $this->db_name . ";charset=utf8"
            ];
            
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
                throw new PDOException("Could not connect to MySQL with any method");
            }
            
        } catch(PDOException $exception) {
            echo "Connection error: " . $exception->getMessage();
        }
        return $this->conn;
    }
}
?>
