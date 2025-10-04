<?php
require_once __DIR__ . '/BaseController.php';
require_once __DIR__ . '/LogController.php';

/**
 * User Controller for managing police agents
 */
class UserController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'users';
    }
    
    /**
     * Create new user/agent
     */
    public function create($data) {
        try {
            // Hash password using MD5
            $hashedPassword = md5($data['password']);
            
            $query = "INSERT INTO {$this->table} (matricule, username, telephone, role, password, statut, first_connection, login_schedule, created_at) 
                     VALUES (:matricule, :username, :telephone, :role, :password, :statut, :first_connection, :login_schedule, NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':matricule', $data['matricule']);
            $stmt->bindParam(':username', $data['username']);
            $stmt->bindParam(':telephone', $data['telephone']);
            $role = $data['role'] ?? 'agent';
            $statut = $data['statut'] ?? 'actif';
            $firstConnection = 'true';
            $loginSchedule = $data['login_schedule'] ?? null;
            
            $stmt->bindParam(':role', $role);
            $stmt->bindParam(':password', $hashedPassword);
            $stmt->bindParam(':statut', $statut);
            $stmt->bindParam(':first_connection', $firstConnection); // Nouveau utilisateur = première connexion
            $stmt->bindParam(':login_schedule', $loginSchedule);
            
            if ($stmt->execute()) {
                $newUserId = $this->db->lastInsertId();
                
                // Log de l'activité de création d'agent
                LogController::record(
                    $data['matricule'], // Matricule du nouvel agent
                    'Création d\'agent',
                    [
                        'new_user_id' => $newUserId,
                        'created_by' => 'system', // Ou récupérer l'utilisateur connecté
                        'role' => $data['role'] ?? 'agent',
                        'username' => $data['username']
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                return [
                    'success' => true,
                    'message' => 'Agent créé avec succès',
                    'id' => $newUserId
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la création de l\'agent'
            ];
            
        } catch (Exception $e) {
            // Log l'erreur pour débogage
            error_log("Erreur création utilisateur: " . $e->getMessage());
            error_log("Données reçues: " . json_encode($data));
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Update user
     */
    public function update($id, $data) {
        try {
            $query = "UPDATE {$this->table} SET 
                     username = :username, 
                     telephone = :telephone, 
                     role = :role,
                     statut = :statut,
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':username', $data['username']);
            $stmt->bindParam(':telephone', $data['telephone']);
            $stmt->bindParam(':role', $data['role']);
            $stmt->bindParam(':statut', $data['statut']);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Agent mis à jour avec succès'
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la mise à jour'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la mise à jour: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Get all users with role filtering
     */
    public function getUsers($role = null) {
        try {
            $whereClause = '';
            if ($role) {
                $whereClause = " WHERE role = :role";
            }
            
            $query = "SELECT id, matricule, username, telephone, role, statut, created_at 
                     FROM {$this->table}{$whereClause} 
                     ORDER BY username";
            
            $stmt = $this->db->prepare($query);
            if ($role) {
                $stmt->bindParam(':role', $role);
            }
            $stmt->execute();
            
            return [
                'success' => true,
                'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération des utilisateurs: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Change user password
     */
    public function changePassword($id, $newPassword) {
        try {
            $hashedPassword = md5($newPassword);
            
            $query = "UPDATE {$this->table} SET password = :password, updated_at = NOW() WHERE id = :id";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':password', $hashedPassword);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Mot de passe modifié avec succès'
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors du changement de mot de passe'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors du changement de mot de passe: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Activate/Deactivate user
     */
    public function toggleStatus($id) {
        try {
            $query = "UPDATE {$this->table} SET 
                     statut = CASE WHEN statut = 'actif' THEN 'inactif' ELSE 'actif' END,
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Statut modifié avec succès'
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors du changement de statut'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors du changement de statut: ' . $e->getMessage()
            ];
        }
    }
}
?>
