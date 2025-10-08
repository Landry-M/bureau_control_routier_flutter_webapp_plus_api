<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Avis de Recherche Controller
 */
class AvisRechercheController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'avis_recherche';
    }
    
    /**
     * Create new avis de recherche
     */
    public function create($data) {
        try {
            $query = "INSERT INTO {$this->table} (cible_type, cible_id, motif, niveau, statut, created_by, created_at, updated_at) 
                     VALUES (:cible_type, :cible_id, :motif, :niveau, :statut, :created_by, NOW(), NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':cible_type', $data['cible_type']); // particuliers, vehicule_plaque
            $stmt->bindParam(':cible_id', $data['cible_id']);
            $stmt->bindParam(':motif', $data['motif']);
            $niveau = $data['niveau'] ?? 'moyen'; // faible, moyen, élevé
            $statut = $data['statut'] ?? 'actif';
            $stmt->bindParam(':niveau', $niveau);
            $stmt->bindParam(':statut', $statut);
            $stmt->bindParam(':created_by', $data['created_by']);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Avis de recherche émis avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de l\'émission de l\'avis de recherche'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Update avis de recherche status
     */
    public function updateStatus($id, $statut) {
        try {
            $query = "UPDATE {$this->table} SET statut = :statut, updated_at = NOW() WHERE id = :id";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':statut', $statut);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Statut de l\'avis de recherche mis à jour avec succès'
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
     * Close avis de recherche
     */
    public function close($id, $motif = '') {
        try {
            $query = "UPDATE {$this->table} SET statut = 'fermé', motif_fermeture = :motif, date_fermeture = NOW() WHERE id = :id";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':motif', $motif);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Avis de recherche fermé avec succès'
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la fermeture'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la fermeture: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Get avis de recherche by particulier
     */
    public function getByParticulier($particulierId) {
        try {
            $query = "SELECT * FROM {$this->table}
                     WHERE cible_type IN ('particulier', 'particuliers') AND cible_id = :particulier_id
                     ORDER BY created_at DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':particulier_id', $particulierId);
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
    
    /**
     * Get avis de recherche by vehicule
     */
    public function getByVehicule($vehiculeId) {
        try {
            $query = "SELECT * FROM {$this->table}
                     WHERE cible_type = 'vehicule_plaque' AND cible_id = :vehicule_id
                     ORDER BY created_at DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':vehicule_id', $vehiculeId);
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
    
    /**
     * Get active avis de recherche
     */
    public function getActive() {
        try {
            $query = "SELECT * FROM {$this->table}
                     WHERE statut = 'actif'
                     ORDER BY created_at DESC";
            
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
