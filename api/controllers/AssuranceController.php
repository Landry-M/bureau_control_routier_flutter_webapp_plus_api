<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Assurance Controller
 */
class AssuranceController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'assurance_vehicule';
    }
    
    /**
     * Create new assurance record
     */
    public function create($data) {
        try {
            $query = "INSERT INTO {$this->table} (
                vehicule_plaque_id, societe_assurance, nume_assurance, 
                date_valide_assurance, date_expire_assurance, montant_prime, 
                type_couverture, notes, created_at, updated_at
            ) VALUES (
                :vehicule_plaque_id, :societe_assurance, :nume_assurance,
                :date_valide_assurance, :date_expire_assurance, :montant_prime,
                :type_couverture, :notes, NOW(), NOW()
            )";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':vehicule_plaque_id', $data['vehicule_plaque_id']);
            $stmt->bindParam(':societe_assurance', $data['societe_assurance']);
            $stmt->bindParam(':nume_assurance', $data['nume_assurance']);
            $stmt->bindParam(':date_valide_assurance', $data['date_valide_assurance']);
            $stmt->bindParam(':date_expire_assurance', $data['date_expire_assurance']);
            $stmt->bindParam(':montant_prime', $data['montant_prime']);
            $stmt->bindParam(':type_couverture', $data['type_couverture']);
            $stmt->bindParam(':notes', $data['notes']);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Assurance créée avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la création de l\'assurance'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Get assurance by vehicle ID
     */
    public function getByVehicleId($vehicleId) {
        try {
            $query = "SELECT * FROM {$this->table} WHERE vehicule_plaque_id = :vehicule_plaque_id ORDER BY created_at DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':vehicule_plaque_id', $vehicleId);
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
     * Get current active assurance for a vehicle
     */
    public function getCurrentAssurance($vehicleId) {
        try {
            $query = "SELECT * FROM {$this->table} 
                     WHERE vehicule_plaque_id = :vehicule_plaque_id 
                     AND (date_expire_assurance IS NULL OR date_expire_assurance >= CURDATE())
                     ORDER BY created_at DESC LIMIT 1";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':vehicule_plaque_id', $vehicleId);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                return [
                    'success' => true,
                    'data' => $stmt->fetch(PDO::FETCH_ASSOC)
                ];
            } else {
                return [
                    'success' => false,
                    'message' => 'Aucune assurance active trouvée'
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
     * Get expired assurances
     */
    public function getExpiredAssurances() {
        try {
            $query = "SELECT a.*, v.plaque, v.marque, v.modele 
                     FROM {$this->table} a
                     LEFT JOIN vehicule_plaque v ON a.vehicule_plaque_id = v.id
                     WHERE a.date_expire_assurance < CURDATE()
                     ORDER BY a.date_expire_assurance DESC";
            
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
    
    /**
     * Update assurance
     */
    public function update($id, $data) {
        try {
            $query = "UPDATE {$this->table} SET 
                     societe_assurance = :societe_assurance,
                     nume_assurance = :nume_assurance,
                     date_valide_assurance = :date_valide_assurance,
                     date_expire_assurance = :date_expire_assurance,
                     montant_prime = :montant_prime,
                     type_couverture = :type_couverture,
                     notes = :notes,
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':societe_assurance', $data['societe_assurance']);
            $stmt->bindParam(':nume_assurance', $data['nume_assurance']);
            $stmt->bindParam(':date_valide_assurance', $data['date_valide_assurance']);
            $stmt->bindParam(':date_expire_assurance', $data['date_expire_assurance']);
            $stmt->bindParam(':montant_prime', $data['montant_prime']);
            $stmt->bindParam(':type_couverture', $data['type_couverture']);
            $stmt->bindParam(':notes', $data['notes']);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Assurance mise à jour avec succès'
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
}
?>
