<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Permis Temporaire Controller
 */
class PermisTemporaireController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'permis_temporaire';
    }
    
    /**
     * Create new permis temporaire
     */
    public function create($data) {
        try {
            // Générer un numéro unique si non fourni
            if (empty($data['numero'])) {
                $data['numero'] = $this->generateUniqueNumber();
            }
            
            $query = "INSERT INTO {$this->table} (cible_type, cible_id, numero, motif, date_debut, date_fin, statut, created_by, created_at, updated_at) 
                     VALUES (:cible_type, :cible_id, :numero, :motif, :date_debut, :date_fin, :statut, :created_by, NOW(), NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':cible_type', $data['cible_type']); // 'particulier', 'conducteur', 'vehicule_plaque'
            $stmt->bindParam(':cible_id', $data['cible_id']);
            $stmt->bindParam(':numero', $data['numero']);
            $stmt->bindParam(':motif', $data['motif']);
            $stmt->bindParam(':date_debut', $data['date_debut']);
            $stmt->bindParam(':date_fin', $data['date_fin']);
            $statut = $data['statut'] ?? 'actif';
            $stmt->bindParam(':statut', $statut);
            $stmt->bindParam(':created_by', $data['created_by']);
            
            if ($stmt->execute()) {
                $permisId = $this->db->lastInsertId();
                
                // Générer l'URL de prévisualisation
                $previewUrl = $this->generatePreviewUrl($permisId);
                
                return [
                    'success' => true,
                    'message' => 'Permis temporaire créé avec succès',
                    'id' => $permisId,
                    'numero' => $data['numero'],
                    'preview_url' => $previewUrl
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
     * Generate unique number for permis temporaire
     */
    private function generateUniqueNumber() {
        $prefix = 'PT';
        $year = date('Y');
        $month = date('m');
        
        // Compter les permis existants ce mois-ci
        $query = "SELECT COUNT(*) as count FROM {$this->table} 
                  WHERE numero LIKE :pattern 
                  AND YEAR(created_at) = :year 
                  AND MONTH(created_at) = :month";
        
        $stmt = $this->db->prepare($query);
        $pattern = $prefix . $year . $month . '%';
        $stmt->bindParam(':pattern', $pattern);
        $stmt->bindParam(':year', $year);
        $stmt->bindParam(':month', $month);
        $stmt->execute();
        
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        $count = ($result['count'] ?? 0) + 1;
        
        return $prefix . $year . $month . str_pad($count, 4, '0', STR_PAD_LEFT);
    }
    
    /**
     * Generate preview URL for permis temporaire
     */
    private function generatePreviewUrl($permisId) {
        // URL vers le fichier de prévisualisation
        return "http://localhost:8000/permis_temporaire_display.php?id={$permisId}";
    }
    
    /**
     * Save PDF file to server
     */
    public function savePdf($permisId, $pdfContent) {
        try {
            // Créer le dossier s'il n'existe pas
            $uploadDir = __DIR__ . '/../uploads/permis_temporaire/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0755, true);
            }
            
            // Générer le nom du fichier
            $filename = "permis_temporaire_{$permisId}_" . date('Y-m-d_H-i-s') . '.pdf';
            $filepath = $uploadDir . $filename;
            $relativePath = "/api/uploads/permis_temporaire/{$filename}";
            
            // Sauvegarder le fichier
            if (file_put_contents($filepath, $pdfContent) !== false) {
                // Mettre à jour la base de données avec le chemin du PDF
                $query = "UPDATE {$this->table} SET pdf_path = :pdf_path, updated_at = NOW() WHERE id = :id";
                $stmt = $this->db->prepare($query);
                $stmt->bindParam(':pdf_path', $relativePath);
                $stmt->bindParam(':id', $permisId);
                $stmt->execute();
                
                return [
                    'success' => true,
                    'message' => 'PDF sauvegardé avec succès',
                    'pdf_path' => $relativePath,
                    'filename' => $filename
                ];
            } else {
                return [
                    'success' => false,
                    'message' => 'Erreur lors de la sauvegarde du fichier'
                ];
            }
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la sauvegarde: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Get permis temporaires by particulier
     */
    public function getByParticulier($particulierId) {
        try {
            $query = "SELECT * FROM {$this->table} 
                      WHERE cible_type = 'particulier' AND cible_id = :particulier_id 
                      ORDER BY created_at DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':particulier_id', $particulierId, PDO::PARAM_INT);
            $stmt->execute();
            
            $permis = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'data' => $permis,
                'count' => count($permis)
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération: ' . $e->getMessage()
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
