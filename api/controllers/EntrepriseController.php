<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Entreprise Controller
 */
class EntrepriseController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'entreprises';
    }
    
    /**
     * Create new entreprise
     */
    public function create($data) {
        try {
            $query = "INSERT INTO {$this->table} (nom, rccm, id_nat, adresse, telephone, email, secteur_activite, representant_legal, created_at) 
                     VALUES (:nom, :rccm, :id_nat, :adresse, :telephone, :email, :secteur_activite, :representant_legal, NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':nom', $data['nom']);
            $stmt->bindParam(':rccm', $data['rccm']);
            $stmt->bindParam(':id_nat', $data['id_nat']);
            $stmt->bindParam(':adresse', $data['adresse']);
            $stmt->bindParam(':telephone', $data['telephone']);
            $stmt->bindParam(':email', $data['email']);
            $stmt->bindParam(':secteur_activite', $data['secteur_activite']);
            $stmt->bindParam(':representant_legal', $data['representant_legal']);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Entreprise créée avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la création de l\'entreprise'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Update entreprise
     */
    public function update($id, $data) {
        try {
            $query = "UPDATE {$this->table} SET 
                     nom = :nom, 
                     rccm = :rccm, 
                     id_nat = :id_nat, 
                     adresse = :adresse, 
                     telephone = :telephone,
                     email = :email,
                     secteur_activite = :secteur_activite,
                     representant_legal = :representant_legal,
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':nom', $data['nom']);
            $stmt->bindParam(':rccm', $data['rccm']);
            $stmt->bindParam(':id_nat', $data['id_nat']);
            $stmt->bindParam(':adresse', $data['adresse']);
            $stmt->bindParam(':telephone', $data['telephone']);
            $stmt->bindParam(':email', $data['email']);
            $stmt->bindParam(':secteur_activite', $data['secteur_activite']);
            $stmt->bindParam(':representant_legal', $data['representant_legal']);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Entreprise mise à jour avec succès'
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
     * Search entreprise by RCCM
     */
    public function getByRccm($rccm) {
        try {
            $query = "SELECT * FROM {$this->table} WHERE rccm = :rccm LIMIT 1";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':rccm', $rccm);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                return [
                    'success' => true,
                    'data' => $stmt->fetch(PDO::FETCH_ASSOC)
                ];
            } else {
                return [
                    'success' => false,
                    'message' => 'Entreprise non trouvée'
                ];
            }
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la recherche: ' . $e->getMessage()
            ];
        }
    }
}
?>
