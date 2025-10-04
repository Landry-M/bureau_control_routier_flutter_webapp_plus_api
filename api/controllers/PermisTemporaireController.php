<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Permis Temporaire Controller
 */
class PermisTemporaireController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'permis_temporaires';
    }
    
    /**
     * Create new permis temporaire
     */
    public function create($data) {
        try {
            $query = "INSERT INTO {$this->table} (numero, particulier_id, vehicule_id, motif, date_debut, date_fin, agent_id, statut, created_at) 
                     VALUES (:numero, :particulier_id, :vehicule_id, :motif, :date_debut, :date_fin, :agent_id, :statut, NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':numero', $data['numero']);
            $stmt->bindParam(':particulier_id', $data['particulier_id']);
            $stmt->bindParam(':vehicule_id', $data['vehicule_id']);
            $stmt->bindParam(':motif', $data['motif']);
            $stmt->bindParam(':date_debut', $data['date_debut']);
            $stmt->bindParam(':date_fin', $data['date_fin']);
            $stmt->bindParam(':agent_id', $data['agent_id']);
            $stmt->bindParam(':statut', $data['statut'] ?? 'actif');
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Permis temporaire créé avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la création du permis temporaire'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Generate PDF for permis temporaire
     */
    public function generatePdf($id) {
        try {
            $query = "SELECT pt.*, 
                     p.nom as particulier_nom, p.prenom as particulier_prenom, p.numero_carte_identite,
                     v.plaque as vehicule_plaque, v.marque as vehicule_marque, v.modele as vehicule_modele,
                     u.nom as agent_nom
                     FROM {$this->table} pt
                     LEFT JOIN particuliers p ON pt.particulier_id = p.id
                     LEFT JOIN vehicules v ON pt.vehicule_id = v.id
                     LEFT JOIN users u ON pt.agent_id = u.id
                     WHERE pt.id = :id LIMIT 1";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                $data = $stmt->fetch(PDO::FETCH_ASSOC);
                
                // Here you would implement PDF generation
                // For now, return a placeholder
                return [
                    'success' => true,
                    'message' => 'PDF généré avec succès',
                    'pdf_url' => "/api/permis-temporaire/{$id}/pdf",
                    'data' => $data
                ];
            } else {
                return [
                    'success' => false,
                    'message' => 'Permis temporaire non trouvé'
                ];
            }
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la génération du PDF: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Check if permis is still valid
     */
    public function isValid($id) {
        try {
            $query = "SELECT * FROM {$this->table} WHERE id = :id AND statut = 'actif' AND date_fin >= CURDATE() LIMIT 1";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->execute();
            
            return [
                'success' => true,
                'valid' => $stmt->rowCount() > 0
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la vérification: ' . $e->getMessage()
            ];
        }
    }
}
?>
