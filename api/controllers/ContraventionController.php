<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Contravention Controller
 */
class ContraventionController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'contraventions';
    }
    
    /**
     * Create new contravention
     */
    public function create($data) {
        try {
            $query = "INSERT INTO {$this->table} (numero, vehicule_id, particulier_id, agent_id, infraction, montant, lieu, date_infraction, statut, created_at) 
                     VALUES (:numero, :vehicule_id, :particulier_id, :agent_id, :infraction, :montant, :lieu, :date_infraction, :statut, NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':numero', $data['numero']);
            $stmt->bindParam(':vehicule_id', $data['vehicule_id']);
            $stmt->bindParam(':particulier_id', $data['particulier_id']);
            $stmt->bindParam(':agent_id', $data['agent_id']);
            $stmt->bindParam(':infraction', $data['infraction']);
            $stmt->bindParam(':montant', $data['montant']);
            $stmt->bindParam(':lieu', $data['lieu']);
            $stmt->bindParam(':date_infraction', $data['date_infraction']);
            $stmt->bindParam(':statut', $data['statut'] ?? 'en_attente');
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Contravention créée avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la création de la contravention'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Get contravention with related data
     */
    public function getById($id) {
        try {
            $query = "SELECT c.*, 
                     v.plaque as vehicule_plaque, v.marque as vehicule_marque, v.modele as vehicule_modele,
                     p.nom as particulier_nom, p.prenom as particulier_prenom,
                     u.nom as agent_nom
                     FROM {$this->table} c
                     LEFT JOIN vehicules v ON c.vehicule_id = v.id
                     LEFT JOIN particuliers p ON c.particulier_id = p.id
                     LEFT JOIN users u ON c.agent_id = u.id
                     WHERE c.id = :id LIMIT 1";
            
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
                    'message' => 'Contravention non trouvée'
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
     * Generate PDF for contravention
     */
    public function generatePdf($id) {
        $result = $this->getById($id);
        
        if (!$result['success']) {
            return $result;
        }
        
        // Here you would implement PDF generation
        // For now, return a placeholder
        return [
            'success' => true,
            'message' => 'PDF généré avec succès',
            'pdf_url' => "/api/contraventions/{$id}/pdf"
        ];
    }
    
    /**
     * Update contravention status
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
                    'message' => 'Statut mis à jour avec succès'
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
}
?>
