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
     * Create new entreprise (aligned with entreprises.sql schema)
     */
    public function create($data) {
        try {
            $query = "INSERT INTO {$this->table} (
                        designation, siege_social, gsm, email, personne_contact, fonction_contact,
                        telephone_contact, rccm, secteur, observations, created_at
                      ) VALUES (
                        :designation, :siege_social, :gsm, :email, :personne_contact, :fonction_contact,
                        :telephone_contact, :rccm, :secteur, :observations, NOW()
                      )";

            $stmt = $this->db->prepare($query);

            // Map incoming payload keys to table columns
            $designation = $data['nom'] ?? ($data['designation'] ?? '');
            $siege_social = $data['adresse'] ?? ($data['siege_social'] ?? '');
            $gsm = $data['telephone'] ?? ($data['gsm'] ?? '');
            $email = $data['email'] ?? null;
            $personne_contact = $data['personne_contact'] ?? null;
            $fonction_contact = $data['fonction_contact'] ?? '';
            $telephone_contact = $data['telephone_contact'] ?? '';
            $rccm = $data['rccm'] ?? null;
            $secteur = $data['secteur_activite'] ?? ($data['secteur'] ?? null);
            $observations = $data['notes'] ?? ($data['observations'] ?? null);

            // Validate required fields per schema
            if (trim($designation) === '') {
                throw new Exception('Le nom de l\'entreprise (designation) est requis');
            }
            if (trim($siege_social) === '') {
                throw new Exception('L\'adresse (siege_social) est requise');
            }
            // GSM is now optional - no validation required

            $stmt->bindParam(':designation', $designation);
            $stmt->bindParam(':siege_social', $siege_social);
            $stmt->bindParam(':gsm', $gsm);
            $stmt->bindParam(':email', $email);
            $stmt->bindParam(':personne_contact', $personne_contact);
            $stmt->bindParam(':fonction_contact', $fonction_contact);
            $stmt->bindParam(':telephone_contact', $telephone_contact);
            $stmt->bindParam(':rccm', $rccm);
            $stmt->bindParam(':secteur', $secteur);
            $stmt->bindParam(':observations', $observations);

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
     * Update entreprise (aligned with entreprises.sql schema)
     */
    public function update($id, $data) {
        try {
            $query = "UPDATE {$this->table} SET 
                     designation = :designation, 
                     siege_social = :siege_social, 
                     gsm = :gsm, 
                     email = :email,
                     personne_contact = :personne_contact,
                     fonction_contact = :fonction_contact,
                     telephone_contact = :telephone_contact,
                     rccm = :rccm,
                     secteur = :secteur,
                     observations = :observations,
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':designation', $data['designation']);
            $stmt->bindParam(':siege_social', $data['siege_social']);
            $stmt->bindParam(':gsm', $data['gsm']);
            $stmt->bindParam(':email', $data['email']);
            $stmt->bindParam(':personne_contact', $data['personne_contact']);
            $stmt->bindParam(':fonction_contact', $data['fonction_contact']);
            $stmt->bindParam(':telephone_contact', $data['telephone_contact']);
            $stmt->bindParam(':rccm', $data['rccm']);
            $stmt->bindParam(':secteur', $data['secteur']);
            $stmt->bindParam(':observations', $data['observations']);
            
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
     * Get all entreprises with pagination
     */
    public function getAll($page = 1, $limit = 20, $search = '') {
        try {
            $offset = ($page - 1) * $limit;
            
            // Build search condition
            $whereClause = '';
            $params = [];
            if (!empty($search)) {
                $whereClause = 'WHERE designation LIKE :search1 OR gsm LIKE :search2 OR rccm LIKE :search3 OR email LIKE :search4';
                $searchValue = '%' . $search . '%';
                $params[':search1'] = $searchValue;
                $params[':search2'] = $searchValue;
                $params[':search3'] = $searchValue;
                $params[':search4'] = $searchValue;
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
            
            $entreprises = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'data' => $entreprises,
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
                'message' => 'Erreur lors de la récupération des entreprises: ' . $e->getMessage()
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
