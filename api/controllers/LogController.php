<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Log Controller for activity tracking
 */
class LogController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'activites';
    }
    
    /**
     * Record activity log
     */
    public static function record($username, $action, $details = [], $ip = null, $user_agent = null) {
        try {
            $database = new Database();
            $db = $database->getConnection();
            
            $query = "INSERT INTO activites (username, action, details_operation, ip_address, user_agent, created_at) 
                     VALUES (:username, :action, :details, :ip_address, :user_agent, NOW())";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':username', $username);
            $stmt->bindParam(':action', $action);
            $detailsJson = json_encode($details);
            $stmt->bindParam(':details', $detailsJson);
            $stmt->bindParam(':ip_address', $ip);
            $stmt->bindParam(':user_agent', $user_agent);
            
            return $stmt->execute();
            
        } catch (Exception $e) {
            // Log errors to file or error reporting system
            error_log("Log recording failed: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Get all logs with pagination
     */
    public function getLogs($limit = 100, $offset = 0, $username = null, $action = null) {
        try {
            // Debug
            error_log("LogController::getLogs - Table: {$this->table}");
            error_log("LogController::getLogs - Params: limit=$limit, offset=$offset, username=$username, action=$action");
            
            $whereClause = '';
            $params = [];
            
            if ($username) {
                $whereClause .= " WHERE username LIKE :username";
                $params[':username'] = "%{$username}%";
            }
            
            if ($action) {
                $whereClause .= ($whereClause ? " AND" : " WHERE") . " action LIKE :action";
                $params[':action'] = "%{$action}%";
            }
            
            // Fetch all columns from the table to expose all available information
            $query = "SELECT * FROM {$this->table}{$whereClause} ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
            error_log("LogController::getLogs - Query: $query");
            
            $stmt = $this->db->prepare($query);
            
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            
            $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
            $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
            $stmt->execute();
            
            $logs = $stmt->fetchAll(PDO::FETCH_ASSOC);
            error_log("LogController::getLogs - Nombre de résultats: " . count($logs));
            
            // Fix field name mapping and decode JSON - Updated at 2025-10-03 05:25
            foreach ($logs as &$log) {
                // Convert details_operation to details for frontend compatibility
                if (isset($log['details_operation'])) {
                    $detailsJson = $log['details_operation'];
                    $log['details'] = json_decode($detailsJson, true) ?: [];
                    unset($log['details_operation']);
                } else if (isset($log['details']) && !empty($log['details'])) {
                    $log['details'] = json_decode($log['details'], true) ?: [];
                } else {
                    $log['details'] = [];
                }
            }
            
            return [
                'success' => true,
                'data' => $logs
            ];
            
        } catch (Exception $e) {
            error_log("LogController::getLogs - Erreur: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération des logs: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Add manual log entry
     */
    public function addLog($data) {
        try {
            $query = "INSERT INTO {$this->table} (username, action, details_operation, ip_address, user_agent, created_at) 
                     VALUES (:username, :action, :details, :ip_address, :user_agent, NOW())";
            
            $stmt = $this->db->prepare($query);
            $username = $data['username'];
            $action = $data['action'];
            $details = json_encode($data['details'] ?? []);
            $ipAddress = $data['ip_address'] ?? null;
            $userAgent = $data['user_agent'] ?? null;
            
            $stmt->bindParam(':username', $username);
            $stmt->bindParam(':action', $action);
            $stmt->bindParam(':details', $details);
            $stmt->bindParam(':ip_address', $ipAddress);
            $stmt->bindParam(':user_agent', $userAgent);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Log ajouté avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de l\'ajout du log'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de l\'ajout: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Get activity statistics
     */
    public function getStats($days = 30) {
        try {
            $query = "SELECT 
                     DATE(created_at) as date,
                     COUNT(*) as total_actions,
                     COUNT(DISTINCT username) as unique_users
                     FROM {$this->table} 
                     WHERE created_at >= DATE_SUB(NOW(), INTERVAL :days DAY)
                     GROUP BY DATE(created_at)
                     ORDER BY date DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':days', $days, PDO::PARAM_INT);
            $stmt->execute();
            
            return [
                'success' => true,
                'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage()
            ];
        }
    }
}
?>
