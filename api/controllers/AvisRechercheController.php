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
            // 1. Upload des images si présentes
            $imagesUploaded = [];
            if (isset($_FILES['images']) && !empty($_FILES['images']['name'][0])) {
                $imagesUploaded = $this->uploadImages($_FILES['images'], 'avis_recherche');
            }
            
            // 2. Préparer les données
            $niveau = $data['niveau'] ?? 'moyen'; // faible, moyen, élevé
            $statut = $data['statut'] ?? 'actif';
            $numeroChassis = isset($data['numero_chassis']) ? $data['numero_chassis'] : null;
            $imagesJson = !empty($imagesUploaded) ? json_encode($imagesUploaded) : null;
            
            // 3. Insérer l'avis de recherche
            $query = "INSERT INTO {$this->table} (cible_type, cible_id, motif, niveau, images, numero_chassis, statut, created_by, created_at, updated_at) 
                     VALUES (:cible_type, :cible_id, :motif, :niveau, :images, :numero_chassis, :statut, :created_by, NOW(), NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':cible_type', $data['cible_type']); // particuliers, vehicule_plaque
            $stmt->bindParam(':cible_id', $data['cible_id']);
            $stmt->bindParam(':motif', $data['motif']);
            $stmt->bindParam(':niveau', $niveau);
            $stmt->bindParam(':images', $imagesJson);
            $stmt->bindParam(':numero_chassis', $numeroChassis);
            $stmt->bindParam(':statut', $statut);
            $stmt->bindParam(':created_by', $data['created_by']);
            
            if ($stmt->execute()) {
                $avisId = $this->db->lastInsertId();
                
                // Générer automatiquement le PDF
                try {
                    require_once __DIR__ . '/AvisRecherchePdfController.php';
                    $pdfController = new AvisRecherchePdfController();
                    $pdfResult = $pdfController->generatePdf($avisId);
                    
                    return [
                        'success' => true,
                        'message' => 'Avis de recherche émis avec succès',
                        'id' => $avisId,
                        'pdf' => $pdfResult
                    ];
                } catch (Exception $e) {
                    // Si la génération du PDF échoue, retourner quand même le succès
                    error_log("Warning: PDF generation failed: " . $e->getMessage());
                    return [
                        'success' => true,
                        'message' => 'Avis de recherche émis avec succès (PDF non généré)',
                        'id' => $avisId
                    ];
                }
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de l\'émission de l\'avis de recherche'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Upload multiple images
     */
    private function uploadImages($files, $subfolder) {
        $uploadedPaths = [];
        // Corriger le chemin: depuis /api/controllers/ on remonte à /api/ puis on va dans uploads/
        $uploadDir = __DIR__ . '/../uploads/' . $subfolder . '/';
        
        // Créer le dossier s'il n'existe pas
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }
        
        // Log pour debug
        error_log("Upload directory: " . $uploadDir);
        
        // Gérer les uploads multiples
        if (is_array($files['name'])) {
            error_log("Nombre de fichiers à uploader: " . count($files['name']));
            foreach ($files['name'] as $key => $name) {
                error_log("Traitement fichier $key: $name, erreur: {$files['error'][$key]}");
                
                if ($files['error'][$key] === UPLOAD_ERR_OK) {
                    $extension = pathinfo($name, PATHINFO_EXTENSION);
                    // Valider l'extension
                    $allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
                    if (!in_array(strtolower($extension), $allowedExtensions)) {
                        error_log("Extension non autorisée: $extension");
                        continue;
                    }
                    
                    $filename = uniqid() . '_' . time() . '.' . $extension;
                    $filepath = $uploadDir . $filename;
                    
                    error_log("Tentative d'upload vers: $filepath");
                    if (move_uploaded_file($files['tmp_name'][$key], $filepath)) {
                        $relativePath = 'uploads/' . $subfolder . '/' . $filename;
                        $uploadedPaths[] = $relativePath;
                        error_log("Upload réussi: $relativePath");
                    } else {
                        error_log("Échec de l'upload du fichier $name");
                    }
                } else {
                    error_log("Erreur upload pour fichier $name: " . $files['error'][$key]);
                }
            }
        } else {
            error_log("Les fichiers ne sont pas un tableau");
        }
        
        return $uploadedPaths;
    }
    
    /**
     * Update avis de recherche status
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
                    'message' => 'Statut de l\'avis de recherche mis à jour avec succès'
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
     * Get avis de recherche by particulier
     */
    public function getByParticulier($particulierId) {
        try {
            $query = "SELECT * FROM {$this->table}
                     WHERE cible_type IN ('particulier', 'particuliers') AND cible_id = :particulier_id
                     ORDER BY created_at DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':particulier_id', $particulierId);
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
    
    /**
     * Get avis de recherche by vehicule
     */
    public function getByVehicule($vehiculeId) {
        try {
            $query = "SELECT * FROM {$this->table}
                     WHERE cible_type = 'vehicule_plaque' AND cible_id = :vehicule_id
                     ORDER BY created_at DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':vehicule_id', $vehiculeId);
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
    
    /**
     * Get active avis de recherche
     */
    public function getActive() {
        try {
            $query = "SELECT * FROM {$this->table}
                     WHERE statut = 'actif'
                     ORDER BY created_at DESC";
            
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
