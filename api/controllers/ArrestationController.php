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
     * Convert ISO 8601 date to MySQL format
     */
    private function convertDateToMysql($isoDate) {
        if (!$isoDate) return null;
        
        try {
            $date = new DateTime($isoDate);
            return $date->format('Y-m-d H:i:s');
        } catch (Exception $e) {
            return $isoDate; // Return as-is if conversion fails
        }
    }
    
    /**
     * Create new arrestation
     */
    public function create($data) {
        try {
            // Convert dates to MySQL format
            $dateArrestation = $this->convertDateToMysql($data['date_arrestation']);
            $dateSortiePrison = $this->convertDateToMysql($data['date_sortie_prison'] ?? null);
            
            $query = "INSERT INTO {$this->table} (particulier_id, motif, lieu, date_arrestation, date_sortie_prison, created_by, created_at, updated_at) 
                     VALUES (:particulier_id, :motif, :lieu, :date_arrestation, :date_sortie_prison, :created_by, NOW(), NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':particulier_id', $data['particulier_id']);
            $stmt->bindParam(':motif', $data['motif']);
            $stmt->bindParam(':lieu', $data['lieu']);
            $stmt->bindParam(':date_arrestation', $dateArrestation);
            $stmt->bindParam(':date_sortie_prison', $dateSortiePrison);
            $stmt->bindParam(':created_by', $data['created_by']);
            
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
     * Update liberation status (libération/détention)
     */
    public function updateLiberationStatus($id, $dateSortie = null) {
        try {
            // Convert date to MySQL format
            $dateSortieMysql = $this->convertDateToMysql($dateSortie);
            
            $query = "UPDATE {$this->table} SET 
                     date_sortie_prison = :date_sortie_prison,
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':date_sortie_prison', $dateSortieMysql);
            
            if ($stmt->execute()) {
                $status = $dateSortie ? 'libérée' : 'en détention';
                return [
                    'success' => true,
                    'message' => "Personne marquée comme $status avec succès"
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du statut'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la mise à jour: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Get arrestation with related data
     */
    public function getById($id) {
        try {
            $query = "SELECT a.*, 
                     p.nom as particulier_nom, p.prenom as particulier_prenom, p.gsm as particulier_gsm
                     FROM {$this->table} a
                     LEFT JOIN particuliers p ON a.particulier_id = p.id
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
            $query = "SELECT a.*
                     FROM {$this->table} a
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
                     p.nom as particulier_nom, p.prenom as particulier_prenom, p.gsm as particulier_gsm,
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
