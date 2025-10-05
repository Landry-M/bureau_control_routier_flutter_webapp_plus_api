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
     * Get all particuliers with pagination
     */
    public function getAll($page = 1, $limit = 20, $search = '') {
        try {
            $offset = ($page - 1) * $limit;
            
            // Build search condition
            $whereClause = '';
            $params = [];
            if (!empty($search)) {
                $whereClause = 'WHERE nom LIKE :search OR telephone LIKE :search OR numero_permis LIKE :search';
                $params[':search'] = '%' . $search . '%';
            }
            
            // Count total records
            $countQuery = "SELECT COUNT(*) as total FROM {$this->table} $whereClause";
            $countStmt = $this->db->prepare($countQuery);
            foreach ($params as $key => $value) {
                $countStmt->bindValue($key, $value);
            }
            $countStmt->execute();
            $totalCount = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
            
            // Get paginated data
            $query = "SELECT * FROM {$this->table} $whereClause ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
            $stmt = $this->db->prepare($query);
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
            $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
            $stmt->execute();
            
            $particuliers = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'data' => $particuliers,
                'pagination' => [
                    'page' => $page,
                    'limit' => $limit,
                    'total' => $totalCount,
                    'pages' => ceil($totalCount / $limit)
                ]
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération des particuliers: ' . $e->getMessage()
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

    /**
     * Create particulier with full details and optional contravention
     */
    public function createWithDetails($data, $photos = [], $contraventionPhotos = []) {
        try {
            $this->db->beginTransaction();

            // Helper function for safe data access
            $f = function($k, $def = null) use ($data) { 
                return isset($data[$k]) && $data[$k] !== '' ? $data[$k] : $def; 
            };

            // Insert particulier with full details
            $stmt = $this->db->prepare("
                INSERT INTO particuliers (
                    nom, adresse, profession, date_naissance, genre, numero_national,
                    gsm, email, lieu_naissance, nationalite, etat_civil,
                    personne_contact, personne_contact_telephone, observations,
                    photos, created_at, updated_at
                ) VALUES (
                    :nom, :adresse, :profession, :date_naissance, :genre, :numero_national,
                    :gsm, :email, :lieu_naissance, :nationalite, :etat_civil,
                    :personne_contact, :personne_contact_telephone, :observations,
                    :photos, NOW(), NOW()
                )
            ");

            $stmt->bindValue(':nom', $f('nom'));
            $stmt->bindValue(':adresse', $f('adresse'));
            $stmt->bindValue(':profession', $f('profession'));
            $stmt->bindValue(':date_naissance', $f('date_naissance'));
            $stmt->bindValue(':genre', $f('genre'));
            $stmt->bindValue(':numero_national', $f('numero_national'));
            $stmt->bindValue(':gsm', $f('gsm'));
            $stmt->bindValue(':email', $f('email'));
            $stmt->bindValue(':lieu_naissance', $f('lieu_naissance'));
            $stmt->bindValue(':nationalite', $f('nationalite'));
            $stmt->bindValue(':etat_civil', $f('etat_civil'));
            $stmt->bindValue(':personne_contact', $f('personne_contact'));
            $stmt->bindValue(':personne_contact_telephone', $f('personne_contact_telephone'));
            $stmt->bindValue(':observations', $f('observations'));
            $stmt->bindValue(':photos', json_encode($photos));

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de l\'insertion du particulier');
            }

            $particulierId = $this->db->lastInsertId();

            // Optionally create contravention
            $withContravention = $f('with_contravention', '0');
            if ($withContravention === '1') {
                require_once __DIR__ . '/ContraventionController.php';
                $contraventionController = new ContraventionController();
                
                $contraventionData = [
                    'dossier_id' => $particulierId,
                    'type_dossier' => 'particulier',
                    'date_infraction' => $f('date_infraction'),
                    'lieu' => $f('lieu'),
                    'type_infraction' => $f('type_infraction'),
                    'reference_loi' => $f('reference_loi'),
                    'amende' => $f('amende'),
                    'description' => $f('description'),
                    'payed' => $f('payed', '0'),
                    'photos' => json_encode($contraventionPhotos)
                ];

                $contraventionResult = $contraventionController->create($contraventionData);
                if (!$contraventionResult['success']) {
                    throw new Exception('Erreur lors de la création de la contravention: ' . $contraventionResult['message']);
                }
            }

            $this->db->commit();

            return [
                'success' => true,
                'message' => 'Particulier créé avec succès' . ($withContravention === '1' ? ' avec contravention' : ''),
                'id' => $particulierId
            ];

        } catch (Exception $e) {
            $this->db->rollback();
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
}
?>
