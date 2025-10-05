<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Arrestation Controller
 */
class ArrestationController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'arrestations';
    }
    
    /**
     * Create new arrestation
     */
    public function create($data) {
        try {
            $query = "INSERT INTO {$this->table} (numero, particulier_id, motif, lieu, date_arrestation, agent_id, statut, observations, created_at) 
                     VALUES (:numero, :particulier_id, :motif, :lieu, :date_arrestation, :agent_id, :statut, :observations, NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':numero', $data['numero']);
            $stmt->bindParam(':particulier_id', $data['particulier_id']);
            $stmt->bindParam(':motif', $data['motif']);
            $stmt->bindParam(':lieu', $data['lieu']);
            $stmt->bindParam(':date_arrestation', $data['date_arrestation']);
            $stmt->bindParam(':agent_id', $data['agent_id']);
            $stmt->bindParam(':statut', $data['statut'] ?? 'en_detention');
            $stmt->bindParam(':observations', $data['observations']);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Arrestation enregistrée avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement de l\'arrestation'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Release person (libération)
     */
    public function release($id, $motif_liberation = '') {
        try {
            $query = "UPDATE {$this->table} SET 
                     statut = 'libéré', 
                     motif_liberation = :motif_liberation, 
                     date_liberation = NOW(),
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':motif_liberation', $motif_liberation);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Personne libérée avec succès'
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la libération'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la libération: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Get arrestation with related data
     */
    public function getById($id) {
        try {
            $query = "SELECT a.*, 
                     p.nom as particulier_nom, p.prenom as particulier_prenom, p.numero_carte_identite,
                     u.nom as agent_nom
                     FROM {$this->table} a
                     LEFT JOIN particuliers p ON a.particulier_id = p.id
                     LEFT JOIN users u ON a.agent_id = u.id
                     WHERE a.id = :id LIMIT 1";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                return [
                    'success' => true,
                    'data' => $stmt->fetch(PDO::FETCH_ASSOC)
                ];
            } else {
                return [
                    'success' => false,
                    'message' => 'Arrestation non trouvée'
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
     * Get arrestations by particulier
     */
    public function getByParticulier($particulierId) {
        try {
            $query = "SELECT a.*, 
                     u.nom as agent_nom
                     FROM {$this->table} a
                     LEFT JOIN users u ON a.agent_id = u.id
                     WHERE a.particulier_id = :particulier_id
                     ORDER BY a.date_arrestation DESC, a.created_at DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':particulier_id', $particulierId);
            $stmt->execute();
            
            $arrestations = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'data' => $arrestations,
                'count' => count($arrestations)
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération des arrestations: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get current detainees
     */
    public function getCurrentDetainees() {
        try {
            $query = "SELECT a.*, 
                     p.nom as particulier_nom, p.prenom as particulier_prenom,
                     u.nom as agent_nom
                     FROM {$this->table} a
                     LEFT JOIN particuliers p ON a.particulier_id = p.id
                     LEFT JOIN users u ON a.agent_id = u.id
                     WHERE a.statut = 'en_detention'
                     ORDER BY a.date_arrestation DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->execute();
            
            return [
                'success' => true,
                'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération: ' . $e->getMessage()
            ];
        }
    }
}
?>
