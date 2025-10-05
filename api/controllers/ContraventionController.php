<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Contravention Controller
 */
class ContraventionController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'contraventions';
    }
    
    /**
     * Create new contravention
     */
    public function create($data) {
        try {
            $query = "INSERT INTO {$this->table} (
                dossier_id, type_dossier, date_infraction, lieu, type_infraction, 
                description, reference_loi, amende, payed, photos, created_at
            ) VALUES (
                :dossier_id, :type_dossier, :date_infraction, :lieu, :type_infraction,
                :description, :reference_loi, :amende, :payed, :photos, NOW()
            )";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':dossier_id', $data['dossier_id']);
            $stmt->bindParam(':type_dossier', $data['type_dossier']);
            $stmt->bindParam(':date_infraction', $data['date_infraction']);
            $stmt->bindParam(':lieu', $data['lieu']);
            $stmt->bindParam(':type_infraction', $data['type_infraction']);
            $stmt->bindParam(':description', $data['description']);
            $stmt->bindParam(':reference_loi', $data['reference_loi']);
            $stmt->bindParam(':amende', $data['amende']);
            $payed = $data['payed'] ?? '0';
            $stmt->bindParam(':payed', $payed);
            $stmt->bindParam(':photos', $data['photos']);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Contravention créée avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la création de la contravention'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Get contraventions by vehicule
     */
    public function getByVehicule($vehiculeId) {
        try {
            $query = "SELECT * FROM {$this->table} 
                     WHERE dossier_id = :dossier_id AND type_dossier = 'vehicule_plaque'
                     ORDER BY created_at DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':dossier_id', $vehiculeId);
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
     * Get contravention with related data
     */
    public function getById($id) {
        try {
            $query = "SELECT * FROM {$this->table} WHERE id = :id LIMIT 1";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                return [
                    'success' => true,
                    'data' => $stmt->fetch(PDO::FETCH_ASSOC)
                ];
            } else {
                return [
                    'success' => false,
                    'message' => 'Contravention non trouvée'
                ];
            }
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Generate PDF for contravention
     */
    public function generatePdf($id) {
        $result = $this->getById($id);
        
        if (!$result['success']) {
            return $result;
        }
        
        $contravention = $result['data'];
        
        try {
            // Ensure uploads directory exists
            $uploadsDir = __DIR__ . '/../uploads/contraventions';
            if (!is_dir($uploadsDir)) {
                mkdir($uploadsDir, 0777, true);
            }
            
            // Generate PDF filename
            $filename = 'contravention_' . $id . '_' . date('Y-m-d_H-i-s') . '.pdf';
            $filepath = $uploadsDir . '/' . $filename;
            
            // Generate PDF content using simple HTML to PDF conversion
            $html = $this->generatePdfHtml($contravention);
            
            // Use DomPDF or similar library for PDF generation
            // For now, we'll create a simple text-based PDF using TCPDF-like approach
            $this->createSimplePdf($html, $filepath, $contravention);
            
            // Update contravention record with PDF path (add column if needed)
            $pdfUrl = '/api/uploads/contraventions/' . $filename;
            
            // First, check if pdf_path column exists, if not add it
            try {
                $checkColumn = $this->db->query("SHOW COLUMNS FROM {$this->table} LIKE 'pdf_path'");
                if ($checkColumn->rowCount() == 0) {
                    $this->db->exec("ALTER TABLE {$this->table} ADD COLUMN pdf_path TEXT NULL");
                }
                
                $updateQuery = "UPDATE {$this->table} SET pdf_path = :pdf_path WHERE id = :id";
                $stmt = $this->db->prepare($updateQuery);
                $stmt->bindParam(':pdf_path', $pdfUrl);
                $stmt->bindParam(':id', $id);
                $stmt->execute();
            } catch (Exception $e) {
                // Continue even if update fails - PDF is still generated
                error_log("Warning: Could not update PDF path in database: " . $e->getMessage());
            }
            
            return [
                'success' => true,
                'message' => 'PDF généré avec succès',
                'pdf_url' => $pdfUrl,
                'pdf_path' => $filepath
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la génération du PDF: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Generate HTML content for PDF
     */
    private function generatePdfHtml($contravention) {
        $html = '
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Contravention #' . $contravention['id'] . '</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                .header { text-align: center; margin-bottom: 30px; }
                .content { margin: 20px 0; }
                .field { margin: 10px 0; }
                .label { font-weight: bold; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>CONTRAVENTION</h1>
                <h2>N° ' . $contravention['id'] . '</h2>
            </div>
            
            <div class="content">
                <div class="field">
                    <span class="label">Date d\'infraction:</span> ' . ($contravention['date_infraction'] ?? 'N/A') . '
                </div>
                <div class="field">
                    <span class="label">Lieu:</span> ' . ($contravention['lieu'] ?? 'N/A') . '
                </div>
                <div class="field">
                    <span class="label">Type d\'infraction:</span> ' . ($contravention['type_infraction'] ?? 'N/A') . '
                </div>
                <div class="field">
                    <span class="label">Description:</span> ' . ($contravention['description'] ?? 'N/A') . '
                </div>
                <div class="field">
                    <span class="label">Référence loi:</span> ' . ($contravention['reference_loi'] ?? 'N/A') . '
                </div>
                <div class="field">
                    <span class="label">Montant amende:</span> ' . ($contravention['amende'] ?? 'N/A') . ' FC
                </div>
                <div class="field">
                    <span class="label">Statut paiement:</span> ' . ($contravention['payed'] === 'oui' ? 'Payée' : 'Non payée') . '
                </div>
            </div>
        </body>
        </html>';
        
        return $html;
    }
    
    /**
     * Create simple PDF file
     */
    private function createSimplePdf($html, $filepath, $contravention) {
        // For now, create a simple text file with PDF extension
        // In production, use a proper PDF library like TCPDF or DomPDF
        
        $content = "CONTRAVENTION N° " . $contravention['id'] . "\n\n";
        $content .= "Date d'infraction: " . ($contravention['date_infraction'] ?? 'N/A') . "\n";
        $content .= "Lieu: " . ($contravention['lieu'] ?? 'N/A') . "\n";
        $content .= "Type d'infraction: " . ($contravention['type_infraction'] ?? 'N/A') . "\n";
        $content .= "Description: " . ($contravention['description'] ?? 'N/A') . "\n";
        $content .= "Référence loi: " . ($contravention['reference_loi'] ?? 'N/A') . "\n";
        $content .= "Montant amende: " . ($contravention['amende'] ?? 'N/A') . " FC\n";
        $content .= "Statut paiement: " . ($contravention['payed'] === 'oui' ? 'Payée' : 'Non payée') . "\n";
        
        file_put_contents($filepath, $content);
    }
    
    /**
     * Get contraventions by particulier
     */
    public function getByParticulier($particulierId) {
        try {
            $query = "SELECT * FROM {$this->table} 
                      WHERE dossier_id = :dossier_id 
                      AND type_dossier = 'particulier' 
                      ORDER BY date_infraction DESC, created_at DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':dossier_id', $particulierId);
            $stmt->execute();
            
            $contraventions = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'data' => $contraventions,
                'count' => count($contraventions)
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération des contraventions: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Update contravention status
     */
    public function updateStatus($id, $statut) {
        try {
            $query = "UPDATE {$this->table} SET payed = :statut WHERE id = :id";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':statut', $statut);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Statut mis à jour avec succès'
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
}
?>
