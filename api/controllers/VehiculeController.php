<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Vehicule Controller
 */
class VehiculeController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'vehicules';
    }
    
    /**
     * Create new vehicule
     */
    public function create($data) {
        try {
            $query = "INSERT INTO {$this->table} (plaque, marque, modele, couleur, proprietaire_id, statut, created_at) 
                     VALUES (:plaque, :marque, :modele, :couleur, :proprietaire_id, :statut, NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':plaque', $data['plaque']);
            $stmt->bindParam(':marque', $data['marque']);
            $stmt->bindParam(':modele', $data['modele']);
            $stmt->bindParam(':couleur', $data['couleur']);
            $stmt->bindParam(':proprietaire_id', $data['proprietaire_id']);
            $stmt->bindParam(':statut', $data['statut'] ?? 'actif');
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Véhicule créé avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la création du véhicule'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Update vehicule
     */
    public function update($id, $data) {
        try {
            $query = "UPDATE {$this->table} SET 
                     plaque = :plaque, 
                     marque = :marque, 
                     modele = :modele, 
                     couleur = :couleur, 
                     proprietaire_id = :proprietaire_id,
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':plaque', $data['plaque']);
            $stmt->bindParam(':marque', $data['marque']);
            $stmt->bindParam(':modele', $data['modele']);
            $stmt->bindParam(':couleur', $data['couleur']);
            $stmt->bindParam(':proprietaire_id', $data['proprietaire_id']);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Véhicule mis à jour avec succès'
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
     * Get vehicule by plaque
     */
    public function getByPlaque($plaque) {
        try {
            $query = "SELECT v.*, p.nom as proprietaire_nom, p.prenom as proprietaire_prenom 
                     FROM {$this->table} v 
                     LEFT JOIN particuliers p ON v.proprietaire_id = p.id 
                     WHERE v.plaque = :plaque LIMIT 1";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':plaque', $plaque);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                return [
                    'success' => true,
                    'data' => $stmt->fetch(PDO::FETCH_ASSOC)
                ];
            } else {
                return [
                    'success' => false,
                    'message' => 'Véhicule non trouvé'
                ];
            }
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la recherche: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Retirer un vehicule (suspend)
     */
    public function retirer($id, $motif = '') {
        try {
            $query = "UPDATE {$this->table} SET statut = 'retiré', motif_retrait = :motif, date_retrait = NOW() WHERE id = :id";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':motif', $motif);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Véhicule retiré avec succès'
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors du retrait'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors du retrait: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Remettre un vehicule (reactivate)
     */
    public function remettre($id) {
        try {
            $query = "UPDATE {$this->table} SET statut = 'actif', motif_retrait = NULL, date_retrait = NULL, date_remise = NOW() WHERE id = :id";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Véhicule remis en circulation avec succès'
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la remise en circulation'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la remise en circulation: ' . $e->getMessage()
            ];
        }
    }
}
?>
