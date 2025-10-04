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
            $query = "INSERT INTO {$this->table} (numero, type, nom, prenom, description, photo, derniere_localisation, agent_id, statut, created_at) 
                     VALUES (:numero, :type, :nom, :prenom, :description, :photo, :derniere_localisation, :agent_id, :statut, NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':numero', $data['numero']);
            $stmt->bindParam(':type', $data['type']); // personne, vehicule
            $stmt->bindParam(':nom', $data['nom']);
            $stmt->bindParam(':prenom', $data['prenom']);
            $stmt->bindParam(':description', $data['description']);
            $stmt->bindParam(':photo', $data['photo']);
            $stmt->bindParam(':derniere_localisation', $data['derniere_localisation']);
            $stmt->bindParam(':agent_id', $data['agent_id']);
            $stmt->bindParam(':statut', $data['statut'] ?? 'actif');
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Avis de recherche créé avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la création de l\'avis de recherche'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
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
     * Get active avis de recherche
     */
    public function getActive() {
        try {
            $query = "SELECT a.*, u.nom as agent_nom 
                     FROM {$this->table} a
                     LEFT JOIN users u ON a.agent_id = u.id
                     WHERE a.statut = 'actif'
                     ORDER BY a.created_at DESC";
            
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
