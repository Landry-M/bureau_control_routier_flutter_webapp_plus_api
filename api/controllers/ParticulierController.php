<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Particulier Controller
 */
class ParticulierController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'particuliers';
    }
    
    /**
     * Create new particulier
     */
    public function create($data) {
        try {
            $query = "INSERT INTO {$this->table} (nom, prenom, date_naissance, lieu_naissance, adresse, telephone, email, numero_carte_identite, created_at) 
                     VALUES (:nom, :prenom, :date_naissance, :lieu_naissance, :adresse, :telephone, :email, :numero_carte_identite, NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':nom', $data['nom']);
            $stmt->bindParam(':prenom', $data['prenom']);
            $stmt->bindParam(':date_naissance', $data['date_naissance']);
            $stmt->bindParam(':lieu_naissance', $data['lieu_naissance']);
            $stmt->bindParam(':adresse', $data['adresse']);
            $stmt->bindParam(':telephone', $data['telephone']);
            $stmt->bindParam(':email', $data['email']);
            $stmt->bindParam(':numero_carte_identite', $data['numero_carte_identite']);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Particulier créé avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la création du particulier'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Update particulier
     */
    public function update($id, $data) {
        try {
            $query = "UPDATE {$this->table} SET 
                     nom = :nom, 
                     prenom = :prenom, 
                     date_naissance = :date_naissance, 
                     lieu_naissance = :lieu_naissance, 
                     adresse = :adresse,
                     telephone = :telephone,
                     email = :email,
                     numero_carte_identite = :numero_carte_identite,
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':nom', $data['nom']);
            $stmt->bindParam(':prenom', $data['prenom']);
            $stmt->bindParam(':date_naissance', $data['date_naissance']);
            $stmt->bindParam(':lieu_naissance', $data['lieu_naissance']);
            $stmt->bindParam(':adresse', $data['adresse']);
            $stmt->bindParam(':telephone', $data['telephone']);
            $stmt->bindParam(':email', $data['email']);
            $stmt->bindParam(':numero_carte_identite', $data['numero_carte_identite']);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Particulier mis à jour avec succès'
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
     * Search particulier by carte identite
     */
    public function getByCarteIdentite($numero) {
        try {
            $query = "SELECT * FROM {$this->table} WHERE numero_carte_identite = :numero LIMIT 1";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':numero', $numero);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                return [
                    'success' => true,
                    'data' => $stmt->fetch(PDO::FETCH_ASSOC)
                ];
            } else {
                return [
                    'success' => false,
                    'message' => 'Particulier non trouvé'
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
     * Get arrestations for a particulier
     */
    public function getArrestations($id) {
        try {
            $query = "SELECT a.*, u.nom as agent_nom 
                     FROM arrestations a 
                     LEFT JOIN users u ON a.agent_id = u.id 
                     WHERE a.particulier_id = :id 
                     ORDER BY a.created_at DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->execute();
            
            return [
                'success' => true,
                'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération des arrestations: ' . $e->getMessage()
            ];
        }
    }
}
?>
