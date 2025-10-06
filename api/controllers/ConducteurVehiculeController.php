<?php

require_once __DIR__ . '/BaseController.php';
require_once __DIR__ . '/VehiculeController.php';
require_once __DIR__ . '/ContraventionController.php';
require_once __DIR__ . '/LogController.php';

class ConducteurVehiculeController extends BaseController {
    
    public function createWithDetails($data, $files = []) {
        try {
            $this->db->beginTransaction();
            
            // Validation des champs requis
            if (empty($data['nom']) || empty($data['plaque']) || empty($data['marque']) || empty($data['modele'])) {
                throw new Exception('Les champs nom, plaque, marque et modèle sont requis');
            }
            
            // Vérifier l'unicité de la plaque
            $vehiculeController = new VehiculeController();
            if ($vehiculeController->plaqueExists($data['plaque'])) {
                throw new Exception('Cette plaque d\'immatriculation existe déjà dans la base de données');
            }
            
            // 1. Créer le particulier (conducteur)
            $particulierId = $this->createConducteur($data, $files);
            
            // 2. Créer le véhicule avec référence au particulier
            $vehiculeData = $this->prepareVehiculeData($data, $particulierId);
            $vehiculeId = $this->createVehicule($vehiculeData);
            
            // 3. Créer la contravention si demandée
            $contraventionId = null;
            if (isset($data['with_contravention']) && $data['with_contravention'] === 'true') {
                $contraventionId = $this->createContravention($data, $vehiculeId, $files);
            }
            
            $this->db->commit();
            
            // Logging de l'activité
            $details = [
                'particulier_id' => $particulierId,
                'vehicule_id' => $vehiculeId,
                'plaque' => $data['plaque'],
                'nom_conducteur' => $data['nom'],
                'with_contravention' => isset($data['with_contravention']) ? $data['with_contravention'] : 'false',
                'contravention_id' => $contraventionId,
                'action' => 'creation_particulier_vehicule'
            ];
            
            LogController::record(
                $data['username'] ?? 'system',
                'Création particulier et véhicule',
                json_encode($details),
                $_SERVER['REMOTE_ADDR'] ?? '',
                $_SERVER['HTTP_USER_AGENT'] ?? ''
            );
            
            return [
                'success' => true,
                'message' => 'Particulier et véhicule créés avec succès',
                'particulier_id' => $particulierId,
                'vehicule_id' => $vehiculeId,
                'contravention_id' => $contraventionId
            ];
            
        } catch (Exception $e) {
            $this->db->rollBack();
            return [
                'success' => false,
                'message' => $e->getMessage()
            ];
        }
    }
    
    private function createConducteur($data, $files) {
        // Gestion des uploads de photos
        $photoPath = $this->handleFileUpload($files, 'photo', 'particuliers') ?: '';
        $permisRectoPath = $this->handleFileUpload($files, 'permis_recto', 'particuliers');
        $permisVersoPath = $this->handleFileUpload($files, 'permis_verso', 'particuliers');
        
        $sql = "INSERT INTO particuliers (
            nom, adresse, date_naissance, photo, 
            permis_recto, permis_verso, permis_date_emission, permis_date_expiration, 
            observations, created_at
        ) VALUES (
            :nom, :adresse, :date_naissance, :photo,
            :permis_recto, :permis_verso, :permis_date_emission, :permis_date_expiration,
            :observations, NOW()
        )";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            ':nom' => $data['nom'],
            ':adresse' => $data['adresse'] ?? null,
            ':date_naissance' => $this->formatDate($data['date_naissance'] ?? null),
            ':photo' => $photoPath,
            ':permis_recto' => $permisRectoPath,
            ':permis_verso' => $permisVersoPath,
            ':permis_date_emission' => $this->formatDate($data['permis_valide_le'] ?? null),
            ':permis_date_expiration' => $this->formatDate($data['permis_expire_le'] ?? null),
            ':observations' => $data['observations'] ?? null
        ]);
        
        return $this->db->lastInsertId();
    }
    
    private function prepareVehiculeData($data, $particulierId) {
        return [
            'plaque' => $data['plaque'],
            'marque' => $data['marque'],
            'modele' => $data['modele'],
            'couleur' => $data['couleur'] ?? null,
            'annee' => $data['annee'] ?? null,
            'chassis' => $data['chassis'] ?? null,
            'moteur' => $data['moteur'] ?? null,
            'proprietaire' => $data['proprietaire'] ?? $data['nom'], // Par défaut le conducteur
            'usage' => $data['usage'] ?? null,
            'date_importation' => $data['date_importation'] ?? null,
            'date_plaque' => $data['date_plaque'] ?? null,
            'conducteur_id' => $particulierId, // Référence au particulier
            'en_circulation' => '1'
        ];
    }
    
    private function createVehicule($vehiculeData) {
        $sql = "INSERT INTO vehicule_plaque (
            plaque, marque, modele, couleur, annee, numero_chassis, num_moteur,
            proprietaire, `usage`, date_importation, plaque_valide_le,
            conducteur_id, en_circulation, created_at
        ) VALUES (
            :plaque, :marque, :modele, :couleur, :annee, :numero_chassis, :num_moteur,
            :proprietaire, :usage, :date_importation, :plaque_valide_le,
            :conducteur_id, :en_circulation, NOW()
        )";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            ':plaque' => $vehiculeData['plaque'],
            ':marque' => $vehiculeData['marque'],
            ':modele' => $vehiculeData['modele'],
            ':couleur' => $vehiculeData['couleur'],
            ':annee' => $vehiculeData['annee'],
            ':numero_chassis' => $vehiculeData['chassis'],
            ':num_moteur' => $vehiculeData['moteur'],
            ':proprietaire' => $vehiculeData['proprietaire'],
            ':usage' => $vehiculeData['usage'],
            ':date_importation' => $this->formatDateTime($vehiculeData['date_importation']),
            ':plaque_valide_le' => $this->formatDateTime($vehiculeData['date_plaque']),
            ':conducteur_id' => $vehiculeData['conducteur_id'],
            ':en_circulation' => $vehiculeData['en_circulation']
        ]);
        
        return $this->db->lastInsertId();
    }
    
    private function createContravention($data, $vehiculeId, $files) {
        // Gestion des photos de contravention
        $contraventionPhotos = [];
        if (isset($files['contravention_photos'])) {
            $photos = is_array($files['contravention_photos']['name']) ? 
                $files['contravention_photos'] : [$files['contravention_photos']];
            
            for ($i = 0; $i < count($photos['name']); $i++) {
                if ($photos['error'][$i] === UPLOAD_ERR_OK) {
                    $photoFile = [
                        'name' => $photos['name'][$i],
                        'type' => $photos['type'][$i],
                        'tmp_name' => $photos['tmp_name'][$i],
                        'error' => $photos['error'][$i],
                        'size' => $photos['size'][$i]
                    ];
                    $photoPath = $this->handleSingleFileUpload($photoFile, 'contraventions');
                    if ($photoPath) {
                        $contraventionPhotos[] = $photoPath;
                    }
                }
            }
        }
        
        $contraventionController = new ContraventionController();
        $contraventionData = [
            'dossier_id' => $vehiculeId,
            'type_dossier' => 'vehicule_plaque',
            'date_infraction' => $this->formatDateTime($data['cv_date_infraction']) ?? date('Y-m-d H:i:s'),
            'lieu' => $data['cv_lieu'] ?? '',
            'type_infraction' => $data['cv_type_infraction'] ?? '',
            'description' => $data['cv_description'] ?? '',
            'reference_loi' => $data['cv_reference_loi'] ?? '',
            'amende' => $data['cv_amende'] ?? '0',
            'payed' => ($data['cv_payed'] ?? '0') === '1' ? 'oui' : 'non',
            'photos' => implode(',', $contraventionPhotos)
        ];
        
        return $contraventionController->create($contraventionData);
    }
    
    private function handleFileUpload($files, $fieldName, $subDir) {
        if (!isset($files[$fieldName]) || $files[$fieldName]['error'] !== UPLOAD_ERR_OK) {
            return null;
        }
        
        return $this->handleSingleFileUpload($files[$fieldName], $subDir);
    }
    
    private function handleSingleFileUpload($file, $subDir) {
        $uploadDir = __DIR__ . "/../uploads/$subDir/";
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }
        
        $filename = uniqid() . '_' . time() . '.' . pathinfo($file['name'], PATHINFO_EXTENSION);
        $uploadPath = $uploadDir . $filename;
        
        if (move_uploaded_file($file['tmp_name'], $uploadPath)) {
            return "/api/uploads/$subDir/$filename";
        }
        
        return null;
    }
    
    private function formatDate($dateString) {
        if (empty($dateString)) {
            return null;
        }
        
        try {
            // Gérer les formats ISO 8601 avec Z
            if (strpos($dateString, 'T') !== false) {
                $dateString = str_replace('Z', '+00:00', $dateString);
            }
            
            $date = new DateTime($dateString);
            return $date->format('Y-m-d');
        } catch (Exception $e) {
            return null;
        }
    }
    
    private function formatDateTime($dateString) {
        if (empty($dateString)) {
            return null;
        }
        
        try {
            // Gérer les formats ISO 8601 avec Z
            if (strpos($dateString, 'T') !== false) {
                $dateString = str_replace('Z', '+00:00', $dateString);
            }
            
            $date = new DateTime($dateString);
            return $date->format('Y-m-d H:i:s');
        } catch (Exception $e) {
            return null;
        }
    }
    
    public function getConducteurById($id) {
        try {
            $sql = "SELECT * FROM particuliers WHERE id = :id";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':id' => $id]);
            
            $conducteur = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$conducteur) {
                return ['success' => false, 'message' => 'Particulier non trouvé'];
            }
            
            return ['success' => true, 'data' => $conducteur];
            
        } catch (Exception $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }
    
    public function getAll($limit = 20, $offset = 0) {
        try {
            $searchTerm = $_GET['search'] ?? '';
            $whereClause = '';
            $params = [];
            
            if (!empty($searchTerm)) {
                $whereClause = "WHERE nom LIKE :search OR adresse LIKE :search OR gsm LIKE :search";
                $params[':search'] = "%$searchTerm%";
            }
            
            // Requête pour compter le total
            $countSql = "SELECT COUNT(*) as total FROM particuliers $whereClause";
            $countStmt = $this->db->prepare($countSql);
            $countStmt->execute($params);
            $total = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
            
            // Requête pour récupérer les données
            $sql = "SELECT * FROM particuliers $whereClause ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
            $stmt = $this->db->prepare($sql);
            
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
            $stmt->bindValue(':offset', (int)$offset, PDO::PARAM_INT);
            
            $stmt->execute();
            $particuliers = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'data' => $particuliers,
                'pagination' => [
                    'total' => (int)$total,
                    'limit' => (int)$limit,
                    'offset' => (int)$offset,
                    'pages' => ceil($total / $limit)
                ]
            ];
            
        } catch (Exception $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }
}
