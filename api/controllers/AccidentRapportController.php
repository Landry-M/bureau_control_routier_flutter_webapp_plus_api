<?php
require_once __DIR__ . '/../config/database.php';

/**
 * Contrôleur pour la création complète de rapports d'accidents
 * Gère les parties impliquées, passagers, photos, etc.
 */
class AccidentRapportController {
    private $db;
    
    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }
    
    /**
     * Créer un rapport d'accident complet
     */
    public function createRapport() {
        try {
            // Récupérer les données POST
            $dateAccident = $_POST['date_accident'] ?? null;
            $lieu = $_POST['lieu'] ?? null;
            $gravite = $_POST['gravite'] ?? null;
            $description = $_POST['description'] ?? null;
            $temoinsData = $_POST['temoins_data'] ?? '[]';
            $partiesData = $_POST['parties_data'] ?? '[]';
            $servicesEtat = $_POST['services_etat_present'] ?? '[]';
            $partieFautiveId = $_POST['partie_fautive_id'] ?? null;
            $raisonFaute = $_POST['raison_faute'] ?? null;
            
            // Validation
            if (!$dateAccident || !$lieu || !$gravite || !$description) {
                return $this->jsonResponse([
                    'success' => false,
                    'message' => 'Champs obligatoires manquants'
                ]);
            }
            
            // Démarrer une transaction
            $this->db->beginTransaction();
            
            // 1. Créer l'accident principal
            $sql = "INSERT INTO accidents (date_accident, lieu, gravite, description, services_etat_present, raison_faute, created_at) 
                    VALUES (:date_accident, :lieu, :gravite, :description, :services_etat, :raison_faute, NOW())";
            
            $stmt = $this->db->prepare($sql);
            $stmt->bindParam(':date_accident', $dateAccident);
            $stmt->bindParam(':lieu', $lieu);
            $stmt->bindParam(':gravite', $gravite);
            $stmt->bindParam(':description', $description);
            $stmt->bindParam(':services_etat', $servicesEtat);
            $stmt->bindParam(':raison_faute', $raisonFaute);
            $stmt->execute();
            
            $accidentId = $this->db->lastInsertId();
            
            // 2. Upload des images principales de l'accident
            $imagesAccident = [];
            if (isset($_FILES['images'])) {
                $imagesAccident = $this->uploadImages($_FILES['images'], 'accidents');
            }
            
            // Mettre à jour l'accident avec les images
            if (!empty($imagesAccident)) {
                $sql = "UPDATE accidents SET images = :images WHERE id = :id";
                $stmt = $this->db->prepare($sql);
                $imagesJson = json_encode($imagesAccident);
                $stmt->bindParam(':images', $imagesJson);
                $stmt->bindParam(':id', $accidentId);
                $stmt->execute();
            }
            
            // 3. Créer les témoins
            $temoins = json_decode($temoinsData, true);
            if (is_array($temoins)) {
                foreach ($temoins as $temoin) {
                    $sql = "INSERT INTO temoins (id_accident, nom, telephone, age, lien_avec_accident, temoignage, created_at) 
                            VALUES (:accident_id, :nom, :telephone, :age, :lien, :temoignage, NOW())";
                    $stmt = $this->db->prepare($sql);
                    $stmt->bindParam(':accident_id', $accidentId);
                    $stmt->bindParam(':nom', $temoin['nom']);
                    $stmt->bindParam(':telephone', $temoin['telephone']);
                    $stmt->bindParam(':age', $temoin['age']);
                    $stmt->bindParam(':lien', $temoin['lien_avec_accident']);
                    $stmt->bindParam(':temoignage', $temoin['temoignage']);
                    $stmt->execute();
                }
            }
            
            // 4. Créer les parties impliquées avec leurs passagers et photos
            $parties = json_decode($partiesData, true);
            if (is_array($parties)) {
                foreach ($parties as $index => $partie) {
                    // Upload des photos de la partie
                    $photosPartie = [];
                    $fileKey = "partie_{$index}_photos";
                    if (isset($_FILES[$fileKey])) {
                        $photosPartie = $this->uploadImages($_FILES[$fileKey], 'parties_impliquees');
                    }
                    
                    // Créer la partie impliquée
                    $sql = "INSERT INTO parties_impliquees 
                            (accident_id, vehicule_plaque_id, role, conducteur_nom, conducteur_etat, 
                             dommages_vehicule, photos, notes, created_at) 
                            VALUES (:accident_id, :vehicule_id, :role, :conducteur_nom, :conducteur_etat, 
                                    :dommages, :photos, :notes, NOW())";
                    
                    $stmt = $this->db->prepare($sql);
                    $stmt->bindParam(':accident_id', $accidentId);
                    $stmt->bindParam(':vehicule_id', $partie['vehicule_plaque_id']);
                    $stmt->bindParam(':role', $partie['role']);
                    $stmt->bindParam(':conducteur_nom', $partie['conducteur_nom']);
                    $stmt->bindParam(':conducteur_etat', $partie['conducteur_etat']);
                    $stmt->bindParam(':dommages', $partie['dommages_vehicule']);
                    $photosJson = json_encode($photosPartie);
                    $stmt->bindParam(':photos', $photosJson);
                    $stmt->bindParam(':notes', $partie['notes']);
                    $stmt->execute();
                    
                    $partieId = $this->db->lastInsertId();
                    
                    // Créer les passagers de cette partie
                    $passagers = json_decode($partie['passagers'], true);
                    if (is_array($passagers)) {
                        foreach ($passagers as $passager) {
                            $sql = "INSERT INTO passagers_partie (partie_id, nom, etat, created_at) 
                                    VALUES (:partie_id, :nom, :etat, NOW())";
                            $stmt = $this->db->prepare($sql);
                            $stmt->bindParam(':partie_id', $partieId);
                            $stmt->bindParam(':nom', $passager['nom']);
                            $stmt->bindParam(':etat', $passager['etat']);
                            $stmt->execute();
                        }
                    }
                }
            }
            
            // 5. Mettre à jour la partie fautive si spécifiée
            if ($partieFautiveId && is_numeric($partieFautiveId)) {
                // Récupérer l'ID réel de la partie basé sur l'index
                $sql = "SELECT id FROM parties_impliquees WHERE accident_id = :accident_id ORDER BY id ASC LIMIT 1 OFFSET :offset";
                $stmt = $this->db->prepare($sql);
                $stmt->bindParam(':accident_id', $accidentId);
                $offset = intval($partieFautiveId) - 1;
                $stmt->bindParam(':offset', $offset, PDO::PARAM_INT);
                $stmt->execute();
                $partieRow = $stmt->fetch(PDO::FETCH_ASSOC);
                
                if ($partieRow) {
                    $sql = "UPDATE accidents SET partie_fautive_id = :partie_id WHERE id = :accident_id";
                    $stmt = $this->db->prepare($sql);
                    $stmt->bindParam(':partie_id', $partieRow['id']);
                    $stmt->bindParam(':accident_id', $accidentId);
                    $stmt->execute();
                }
            }
            
            // Commit de la transaction
            $this->db->commit();
            
            return $this->jsonResponse([
                'success' => true,
                'state' => true,
                'message' => 'Rapport d\'accident créé avec succès',
                'accident_id' => $accidentId
            ]);
            
        } catch (Exception $e) {
            // Rollback en cas d'erreur
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            
            return $this->jsonResponse([
                'success' => false,
                'message' => 'Erreur lors de la création du rapport: ' . $e->getMessage()
            ]);
        }
    }
    
    /**
     * Upload multiple images
     */
    private function uploadImages($files, $subfolder) {
        $uploadedPaths = [];
        $uploadDir = __DIR__ . '/../uploads/' . $subfolder . '/';
        
        // Créer le dossier s'il n'existe pas
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }
        
        // Gérer les uploads multiples
        if (is_array($files['name'])) {
            foreach ($files['name'] as $key => $name) {
                if ($files['error'][$key] === UPLOAD_ERR_OK) {
                    $extension = pathinfo($name, PATHINFO_EXTENSION);
                    $filename = uniqid() . '_' . time() . '.' . $extension;
                    $filepath = $uploadDir . $filename;
                    
                    if (move_uploaded_file($files['tmp_name'][$key], $filepath)) {
                        $uploadedPaths[] = '/api/uploads/' . $subfolder . '/' . $filename;
                    }
                }
            }
        }
        
        return $uploadedPaths;
    }
    
    /**
     * Retourner une réponse JSON
     */
    private function jsonResponse($data) {
        header('Content-Type: application/json');
        echo json_encode($data);
        exit;
    }
    
    /**
     * Récupérer les détails complets d'un accident
     */
    public function getAccidentDetails($id) {
        try {
            // Récupérer l'accident
            $sql = "SELECT * FROM accidents WHERE id = :id";
            $stmt = $this->db->prepare($sql);
            $stmt->bindParam(':id', $id);
            $stmt->execute();
            $accident = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$accident) {
                return $this->jsonResponse([
                    'success' => false,
                    'message' => 'Accident non trouvé'
                ]);
            }
            
            // Récupérer les parties impliquées
            $sql = "SELECT pi.*, vp.plaque, vp.marque, vp.modele, vp.couleur, vp.annee 
                    FROM parties_impliquees pi
                    LEFT JOIN vehicule_plaque vp ON pi.vehicule_plaque_id = vp.id
                    WHERE pi.accident_id = :accident_id
                    ORDER BY pi.id ASC";
            $stmt = $this->db->prepare($sql);
            $stmt->bindParam(':accident_id', $id);
            $stmt->execute();
            $parties = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Pour chaque partie, récupérer ses passagers
            foreach ($parties as &$partie) {
                $sql = "SELECT * FROM passagers_partie WHERE partie_id = :partie_id";
                $stmt = $this->db->prepare($sql);
                $stmt->bindParam(':partie_id', $partie['id']);
                $stmt->execute();
                $partie['passagers'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
            }
            
            // Récupérer les témoins
            $sql = "SELECT * FROM temoins WHERE id_accident = :accident_id ORDER BY id ASC";
            $stmt = $this->db->prepare($sql);
            $stmt->bindParam(':accident_id', $id);
            $stmt->execute();
            $temoins = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return $this->jsonResponse([
                'success' => true,
                'accident' => $accident,
                'parties_impliquees' => $parties,
                'temoins' => $temoins
            ]);
            
        } catch (Exception $e) {
            return $this->jsonResponse([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage()
            ]);
        }
    }
}
