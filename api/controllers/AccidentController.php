<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Accident Controller
 */
class AccidentController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'accidents';
    }
    
    /**
     * Create new accident
     */
    public function create($data) {
        try {
            $query = "INSERT INTO {$this->table} (numero, lieu, date_accident, heure, description, gravite, vehicules_impliques, victimes, agent_id, statut, created_at) 
                     VALUES (:numero, :lieu, :date_accident, :heure, :description, :gravite, :vehicules_impliques, :victimes, :agent_id, :statut, NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':numero', $data['numero']);
            $stmt->bindParam(':lieu', $data['lieu']);
            $stmt->bindParam(':date_accident', $data['date_accident']);
            $stmt->bindParam(':heure', $data['heure']);
            $stmt->bindParam(':description', $data['description']);
            $stmt->bindParam(':gravite', $data['gravite']);
            $stmt->bindParam(':vehicules_impliques', json_encode($data['vehicules_impliques']));
            $stmt->bindParam(':victimes', json_encode($data['victimes']));
            $stmt->bindParam(':agent_id', $data['agent_id']);
            $stmt->bindParam(':statut', $data['statut'] ?? 'en_cours');
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Accident enregistré avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement de l\'accident'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Update accident
     */
    public function update($id, $data) {
        try {
            $query = "UPDATE {$this->table} SET 
                     lieu = :lieu, 
                     date_accident = :date_accident, 
                     heure = :heure, 
                     description = :description, 
                     gravite = :gravite,
                     vehicules_impliques = :vehicules_impliques,
                     victimes = :victimes,
                     statut = :statut,
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':lieu', $data['lieu']);
            $stmt->bindParam(':date_accident', $data['date_accident']);
            $stmt->bindParam(':heure', $data['heure']);
            $stmt->bindParam(':description', $data['description']);
            $stmt->bindParam(':gravite', $data['gravite']);
            $stmt->bindParam(':vehicules_impliques', json_encode($data['vehicules_impliques']));
            $stmt->bindParam(':victimes', json_encode($data['victimes']));
            $stmt->bindParam(':statut', $data['statut']);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Accident mis à jour avec succès'
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
     * Get all accidents with pagination and search
     */
    public function getAll($limit = 20, $offset = 0) {
        try {
            $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
            $search = isset($_GET['search']) ? trim($_GET['search']) : '';
            
            $offset = ($page - 1) * $limit;
            
            // Base query
            $whereClause = '';
            $params = [];
            
            if (!empty($search)) {
                $whereClause = "WHERE lieu LIKE :search OR gravite LIKE :search OR description LIKE :search";
                $params[':search'] = "%$search%";
            }
            
            // Count total records
            $countQuery = "SELECT COUNT(*) as total FROM {$this->table} $whereClause";
            $countStmt = $this->db->prepare($countQuery);
            foreach ($params as $key => $value) {
                $countStmt->bindValue($key, $value);
            }
            $countStmt->execute();
            $total = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
            
            // Get paginated data
            $query = "SELECT * FROM {$this->table} $whereClause ORDER BY date_accident DESC, created_at DESC LIMIT :limit OFFSET :offset";
            $stmt = $this->db->prepare($query);
            
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
            $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
            
            $stmt->execute();
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'data' => $data,
                'pagination' => [
                    'page' => $page,
                    'limit' => $limit,
                    'total' => (int)$total,
                    'pages' => ceil($total / $limit)
                ]
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération des accidents: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get accident with related data
     */
    public function getById($id) {
        try {
            $query = "SELECT * FROM {$this->table} WHERE id = :id LIMIT 1";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                $data = $stmt->fetch(PDO::FETCH_ASSOC);
                
                return [
                    'success' => true,
                    'data' => $data
                ];
            } else {
                return [
                    'success' => false,
                    'message' => 'Accident non trouvé'
                ];
            }
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get witnesses for an accident
     */
    public function getWitnesses($accidentId) {
        try {
            $query = "SELECT * FROM temoins WHERE id_accident = :accident_id ORDER BY created_at DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':accident_id', $accidentId);
            $stmt->execute();
            
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'data' => $data
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération des témoins: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get parties impliquées for an accident
     */
    public function getPartiesImpliquees($accidentId) {
        try {
            $query = "SELECT pi.*, vp.plaque, vp.marque, vp.modele, vp.couleur 
                     FROM parties_impliquees pi
                     LEFT JOIN vehicule_plaque vp ON pi.vehicule_plaque_id = vp.id
                     WHERE pi.accident_id = :accident_id 
                     ORDER BY pi.created_at DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':accident_id', $accidentId);
            $stmt->execute();
            
            $parties = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Récupérer les passagers pour chaque partie
            foreach ($parties as &$partie) {
                $passagersQuery = "SELECT * FROM passagers_partie WHERE partie_id = :partie_id ORDER BY created_at";
                $passagersStmt = $this->db->prepare($passagersQuery);
                $passagersStmt->bindParam(':partie_id', $partie['id']);
                $passagersStmt->execute();
                $partie['passagers'] = $passagersStmt->fetchAll(PDO::FETCH_ASSOC);
            }
            
            return [
                'success' => true,
                'data' => $parties
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération des parties impliquées: ' . $e->getMessage()
            ];
        }
    }
}
?>
