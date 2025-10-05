<?php
require_once __DIR__ . '/BaseController.php';
require_once __DIR__ . '/LogController.php';

/**
 * Authentication Controller
 */
class AuthController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'users'; // Adjust table name as needed
    }

    /**
     * Vérifie si l'heure actuelle est dans les plages autorisées d'un login_schedule JSON.
     * Formats supportés (flexibles):
     *  - Array d'objets: [{"day":1-7|"days":[..], "start":"HH:MM", "end":"HH:MM"}, ...]
     *  - Objet par jour: {"1":[{"start":"08:00","end":"17:00"}], "2":[...], ...}
     *  Jours: 1-7 avec 1=Lundi (PHP date('N')).
     */
    private function isWithinLoginSchedule($scheduleJson) {
        try {
            $data = is_array($scheduleJson) ? $scheduleJson : json_decode($scheduleJson, true);
            if (!$data) return true; // si aucun horaire exploitable, ne pas bloquer

            $now = new DateTime('now');
            $currentDay = (int)$now->format('N'); // 1-7 (1=lundi)
            $currentTime = $now->format('H:i');

            // Helper to test a single window
            $inWindow = function($start, $end) use ($currentTime) {
                if (!is_string($start) || !is_string($end)) return false;
                // gestion simple (pas de créneau passant minuit)
                return $currentTime >= $start && $currentTime <= $end;
            };

            // Case 1: associative by day keys (numeric format: "1", "2", etc.)
            if (isset($data['1']) || isset($data['2']) || isset($data['3']) || isset($data['4']) || isset($data['5']) || isset($data['6']) || isset($data['7'])) {
                $windows = $data[(string)$currentDay] ?? [];
                if (!is_array($windows)) return true; // format inattendu => ne pas bloquer
                foreach ($windows as $w) {
                    if ($inWindow($w['start'] ?? null, $w['end'] ?? null)) return true;
                }
                return false;
            }
            
            // Case 1b: associative by day names (textual format: "Lundi", "Mardi", etc.)
            $dayNames = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
            if (isset($data['Lundi']) || isset($data['Mardi']) || isset($data['Mercredi']) || isset($data['Jeudi']) || isset($data['Vendredi']) || isset($data['Samedi']) || isset($data['Dimanche'])) {
                $todayName = $dayNames[$currentDay];
                $todaySchedule = $data[$todayName] ?? null;
                
                if (!$todaySchedule || !is_array($todaySchedule)) {
                    return true; // pas d'horaire défini pour aujourd'hui => ne pas bloquer
                }
                
                // Vérifier si le jour est activé
                $enabled = $todaySchedule['enabled'] ?? true;
                if (!$enabled) {
                    return false; // jour désactivé => bloquer
                }
                
                // Vérifier l'heure si le jour est activé
                $start = $todaySchedule['start'] ?? null;
                $end = $todaySchedule['end'] ?? null;
                
                if ($start && $end) {
                    return $inWindow($start, $end);
                }
                
                return true; // pas d'heure définie => autoriser
            }

            // Case 2: array of entries with day/days
            if (array_is_list($data)) {
                foreach ($data as $entry) {
                    if (!is_array($entry)) continue;
                    $days = [];
                    if (isset($entry['day'])) $days[] = (int)$entry['day'];
                    if (isset($entry['days']) && is_array($entry['days'])) {
                        foreach ($entry['days'] as $d) { $days[] = (int)$d; }
                    }
                    if (empty($days)) $days = range(1,7); // si non spécifié, tous les jours
                    if (in_array($currentDay, $days, true)) {
                        if ($inWindow($entry['start'] ?? null, $entry['end'] ?? null)) return true;
                    }
                }
                return false;
            }

            // Autres formats: ne pas bloquer
            return true;
        } catch (Exception $e) {
            // En cas d'erreur de parsing, ne pas bloquer la connexion
            return true;
        }
    }
    
    /**
     * Authenticate user
     */
    public function login($matricule, $password) {
        try {
            $query = "SELECT * FROM {$this->table} WHERE matricule = :matricule OR username = :matricule LIMIT 1";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':matricule', $matricule);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                $user = $stmt->fetch(PDO::FETCH_ASSOC);
                
                // Check password - adjust column name based on your table
                $stored_password = $user['password'] ?? $user['mot_de_passe'] ?? '';
                $password_md5 = md5($password);
                
                // Check password using MD5 hash
                if ($password_md5 === $stored_password) {
                    // Enforce working hours for non-superadmin
                    $role = strtolower($user['role'] ?? 'agent');
                    if ($role !== 'superadmin') {
                        $scheduleJson = $user['login_schedule'] ?? null;
                        if (!empty($scheduleJson)) {
                            if (!$this->isWithinLoginSchedule($scheduleJson)) {
                                // Log attempt out of schedule
                                LogController::record(
                                    $user['matricule'],
                                    'Tentative de connexion en dehors des horaires',
                                    [
                                        'user_id' => $user['id'],
                                        'role' => $user['role'] ?? 'agent',
                                    ],
                                    $_SERVER['REMOTE_ADDR'] ?? null,
                                    $_SERVER['HTTP_USER_AGENT'] ?? null
                                );
                                return [
                                    'success' => false,
                                    'message' => "Connexion refusée: en dehors des heures de travail",
                                ];
                            }
                        }
                    }
                    // Check if this is first connection using database field
                    $firstConnectionValue = $user['first_connection'] ?? null;
                    $isFirstConnection = isset($user['first_connection']) && 
                        ($firstConnectionValue == 1 || $firstConnectionValue === 'true' || $firstConnectionValue === true);
                    
                    // Log de l'activité de connexion
                    LogController::record(
                        $user['matricule'],
                        'Connexion',
                        [
                            'user_id' => $user['id'],
                            'role' => $user['role'] ?? 'agent',
                            'first_connection' => $isFirstConnection
                        ],
                        $_SERVER['REMOTE_ADDR'] ?? null,
                        $_SERVER['HTTP_USER_AGENT'] ?? null
                    );
                    
                    return [
                        'success' => true,
                        'user' => $user,
                        'token' => $this->generateToken($user),
                        'role' => $user['role'] ?? 'agent',
                        'username' => $user['nom'] ?? $user['username'] ?? $user['matricule'] ?? 'Utilisateur',
                        'first_connection' => $isFirstConnection
                    ];
                }
            }
            
            // Log de la tentative de connexion échouée
            LogController::record(
                $matricule,
                'Tentative de connexion échouée',
                [
                    'reason' => 'invalid_credentials',
                    'attempted_matricule' => $matricule
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );
            
            return [
                'success' => false,
                'message' => 'Identifiants invalides'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur de base de données: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Change user password
     */
    public function changePassword($userId, $oldPassword, $newPassword) {
        try {
            // First verify old password
            $query = "SELECT password FROM {$this->table} WHERE id = :id LIMIT 1";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $userId);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                $user = $stmt->fetch(PDO::FETCH_ASSOC);
                $stored_password = $user['password'];
                
                if (md5($oldPassword) === $stored_password) {
                    // Update with new password using MD5
                    $hashedPassword = md5($newPassword);
                    $updateQuery = "UPDATE {$this->table} SET password = :password WHERE id = :id";
                    $updateStmt = $this->db->prepare($updateQuery);
                    $updateStmt->bindParam(':password', $hashedPassword);
                    $updateStmt->bindParam(':id', $userId);
                    
                    if ($updateStmt->execute()) {
                        // Log de l'activité de changement de mot de passe
                        LogController::record(
                            $userId,
                            'Changement de mot de passe',
                            [
                                'user_id' => $userId,
                                'action' => 'password_change'
                            ],
                            $_SERVER['REMOTE_ADDR'] ?? null,
                            $_SERVER['HTTP_USER_AGENT'] ?? null
                        );
                        
                        return [
                            'success' => true,
                            'message' => 'Mot de passe modifié avec succès'
                        ];
                    }
                }
            }
            
            return [
                'success' => false,
                'message' => 'Mot de passe incorrect'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors du changement de mot de passe: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Complete first connection by updating password
     */
    public function completeFirstConnection($userId, $newPassword, $confirmPassword) {
        try {
            // Validate passwords match
            if ($newPassword !== $confirmPassword) {
                return [
                    'success' => false,
                    'message' => 'Les mots de passe ne correspondent pas'
                ];
            }
            
            // Validate password strength (minimum 6 characters)
            if (strlen($newPassword) < 6) {
                return [
                    'success' => false,
                    'message' => 'Le mot de passe doit contenir au moins 6 caractères'
                ];
            }
            
            // Hash the new password using MD5
            $hashedPassword = md5($newPassword);
            
            // Update password and mark as not first connection
            $query = "UPDATE {$this->table} SET 
                     password = :password, 
                     first_connection = 'false',
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':password', $hashedPassword);
            $stmt->bindParam(':id', $userId);
            
            if ($stmt->execute()) {
                // Log de l'activité de première connexion
                LogController::record(
                    $userId, // Utiliser l'ID utilisateur
                    'Première connexion - Changement de mot de passe',
                    [
                        'user_id' => $userId,
                        'action' => 'password_change_first_connection'
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                return [
                    'success' => true,
                    'message' => 'Mot de passe mis à jour avec succès'
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du mot de passe'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la mise à jour: ' . $e->getMessage()
            ];
        }
    }
    
    
    /**
     * Generate simple token (replace with JWT in production)
     */
    private function generateToken($user) {
        return 'token_' . $user['id'] . '_' . time();
    }
}
?>
