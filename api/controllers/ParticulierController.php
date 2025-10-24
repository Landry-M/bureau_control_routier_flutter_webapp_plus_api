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
            $query = "INSERT INTO {$this->table} (nom, date_naissance, lieu_naissance, adresse, gsm, email, numero_national, created_at) 
                     VALUES (:nom, :date_naissance, :lieu_naissance, :adresse, :gsm, :email, :numero_national, NOW())";
            
            $stmt = $this->db->prepare($query);
            $gsm = $data['gsm'] ?? $data['telephone'] ?? null;
            $numeroNational = $data['numero_national'] ?? $data['numero_carte_identite'] ?? null;
            
            $stmt->bindParam(':nom', $data['nom']);
            $stmt->bindParam(':date_naissance', $data['date_naissance']);
            $stmt->bindParam(':lieu_naissance', $data['lieu_naissance']);
            $stmt->bindParam(':adresse', $data['adresse']);
            $stmt->bindParam(':gsm', $gsm);
            $stmt->bindParam(':email', $data['email']);
            $stmt->bindParam(':numero_national', $numeroNational);
            
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
                     date_naissance = :date_naissance, 
                     lieu_naissance = :lieu_naissance, 
                     adresse = :adresse,
                     gsm = :gsm,
                     email = :email,
                     numero_national = :numero_national,
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $gsm = $data['gsm'] ?? $data['telephone'] ?? null;
            $numeroNational = $data['numero_national'] ?? $data['numero_carte_identite'] ?? null;
            
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':nom', $data['nom']);
            $stmt->bindParam(':date_naissance', $data['date_naissance']);
            $stmt->bindParam(':lieu_naissance', $data['lieu_naissance']);
            $stmt->bindParam(':adresse', $data['adresse']);
            $stmt->bindParam(':gsm', $gsm);
            $stmt->bindParam(':email', $data['email']);
            $stmt->bindParam(':numero_national', $numeroNational);
            
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
     * Update particulier with complete data including photos
     */
    public function updateComplete($id, $data, $files = []) {
        try {
            // Vérifier que le particulier existe
            $checkQuery = "SELECT id FROM {$this->table} WHERE id = :id";
            $checkStmt = $this->db->prepare($checkQuery);
            $checkStmt->bindParam(':id', $id);
            $checkStmt->execute();
            
            if ($checkStmt->rowCount() === 0) {
                return [
                    'success' => false,
                    'message' => 'Particulier non trouvé'
                ];
            }

            // Gérer l'upload des photos
            $photoFields = [];
            $uploadDir = __DIR__ . '/../uploads/particuliers/';
            
            // Créer le dossier s'il n'existe pas
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0755, true);
            }

            foreach (['photo', 'permis_recto', 'permis_verso'] as $photoType) {
                if (isset($files[$photoType]) && $files[$photoType]['error'] === UPLOAD_ERR_OK) {
                    $file = $files[$photoType];
                    $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
                    
                    // Vérifier l'extension
                    if (!in_array($extension, ['jpg', 'jpeg', 'png', 'gif'])) {
                        return [
                            'success' => false,
                            'message' => "Format d'image non supporté pour {$photoType}. Utilisez JPG, PNG ou GIF."
                        ];
                    }
                    
                    // Générer un nom unique
                    $fileName = $photoType . '_' . $id . '_' . time() . '.' . $extension;
                    $filePath = $uploadDir . $fileName;
                    
                    // Déplacer le fichier
                    if (move_uploaded_file($file['tmp_name'], $filePath)) {
                        $photoFields[$photoType] = '/api/uploads/particuliers/' . $fileName;
                    } else {
                        return [
                            'success' => false,
                            'message' => "Erreur lors de l'upload de {$photoType}"
                        ];
                    }
                }
            }

            // Construire la requête de mise à jour
            $updateFields = [
                'nom = :nom',
                'gsm = :gsm',
                'adresse = :adresse',
                'numero_permis = :numero_permis',
                'observations = :observations',
                'updated_at = NOW()'
            ];

            // Ajouter genre/sexe si fourni
            if (!empty($data['sexe']) || !empty($data['genre'])) {
                $updateFields[] = 'genre = :genre';
            }

            // Ajouter categorie_permis si fourni
            if (!empty($data['categorie_permis'])) {
                $updateFields[] = 'categorie_permis = :categorie_permis';
            }

            // Ajouter les dates si elles sont fournies
            if (!empty($data['date_naissance'])) {
                $updateFields[] = 'date_naissance = :date_naissance';
            }
            if (!empty($data['permis_date_emission'])) {
                $updateFields[] = 'permis_date_emission = :permis_date_emission';
            }
            if (!empty($data['permis_date_expiration'])) {
                $updateFields[] = 'permis_date_expiration = :permis_date_expiration';
            }

            // Ajouter les photos si elles ont été uploadées
            foreach ($photoFields as $field => $path) {
                $updateFields[] = "{$field} = :{$field}";
            }

            $query = "UPDATE {$this->table} SET " . implode(', ', $updateFields) . " WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':nom', $data['nom']);
            $stmt->bindParam(':gsm', $data['gsm']);
            $stmt->bindParam(':adresse', $data['adresse']);
            $stmt->bindParam(':numero_permis', $data['numero_permis']);
            $stmt->bindParam(':observations', $data['observations']);

            // Bind genre/sexe si fourni
            if (!empty($data['sexe']) || !empty($data['genre'])) {
                $genre = $data['genre'] ?? $data['sexe'];
                $stmt->bindParam(':genre', $genre);
            }

            // Bind categorie_permis si fourni
            if (!empty($data['categorie_permis'])) {
                $stmt->bindParam(':categorie_permis', $data['categorie_permis']);
            }

            // Bind des dates si elles sont fournies
            if (!empty($data['date_naissance'])) {
                $stmt->bindParam(':date_naissance', $data['date_naissance']);
            }
            if (!empty($data['permis_date_emission'])) {
                $stmt->bindParam(':permis_date_emission', $data['permis_date_emission']);
            }
            if (!empty($data['permis_date_expiration'])) {
                $stmt->bindParam(':permis_date_expiration', $data['permis_date_expiration']);
            }

            // Bind des photos
            foreach ($photoFields as $field => $path) {
                $stmt->bindParam(":{$field}", $path);
            }
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Particulier modifié avec succès',
                    'photos_uploaded' => array_keys($photoFields)
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la modification'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la modification: ' . $e->getMessage()
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
     * Get particulier by ID
     */
    public function getById($id) {
        try {
            $query = "SELECT * FROM {$this->table} WHERE id = :id LIMIT 1";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id, PDO::PARAM_INT);
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
                'message' => 'Erreur lors de la récupération du particulier: ' . $e->getMessage()
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
                $whereClause = 'WHERE nom LIKE :search1 OR gsm LIKE :search2 OR adresse LIKE :search3';
                $searchParam = '%' . $search . '%';
                $params[':search1'] = $searchParam;
                $params[':search2'] = $searchParam;
                $params[':search3'] = $searchParam;
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
     * Check if a particulier with the given name already exists
     */
    public function nomExists($nom) {
        try {
            if (empty($nom) || trim($nom) === '') {
                return false;
            }

            $query = "SELECT COUNT(*) as count FROM {$this->table} WHERE LOWER(TRIM(nom)) = LOWER(TRIM(:nom))";
            $stmt = $this->db->prepare($query);
            $nomTrimmed = trim($nom);
            $stmt->bindParam(':nom', $nomTrimmed);
            $stmt->execute();
            
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return ($result['count'] ?? 0) > 0;
            
        } catch (Exception $e) {
            // En cas d'erreur SQL, considérer que le nom existe pour éviter les doublons
            error_log('Erreur lors de la vérification du nom particulier: ' . $e->getMessage());
            return true;
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

            // Vérifier que le nom n'est pas vide
            $nom = $f('nom');
            if (!$nom || trim($nom) === '') {
                return [
                    'success' => false,
                    'message' => 'Le nom complet est requis'
                ];
            }

            // Vérifier l'unicité du nom
            if ($this->nomExists($nom)) {
                return [
                    'success' => false,
                    'message' => 'Un particulier avec ce nom existe déjà dans la base de données. Veuillez vérifier le nom.'
                ];
            }

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
