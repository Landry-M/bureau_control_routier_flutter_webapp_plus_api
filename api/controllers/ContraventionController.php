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
            // Vérifier si les colonnes latitude/longitude existent, sinon les ajouter
            try {
                $checkLat = $this->db->query("SHOW COLUMNS FROM {$this->table} LIKE 'latitude'");
                $checkLng = $this->db->query("SHOW COLUMNS FROM {$this->table} LIKE 'longitude'");
                
                if ($checkLat->rowCount() == 0 || $checkLng->rowCount() == 0) {
                    $this->db->exec("ALTER TABLE {$this->table} 
                        ADD COLUMN latitude DECIMAL(10, 8) DEFAULT NULL,
                        ADD COLUMN longitude DECIMAL(11, 8) DEFAULT NULL");
                }
            } catch (Exception $e) {
                // Continue même si l'ajout des colonnes échoue
                error_log("Warning: Could not add lat/lng columns: " . $e->getMessage());
            }

            $query = "INSERT INTO {$this->table} (
                dossier_id, type_dossier, date_infraction, lieu, type_infraction, 
                description, reference_loi, amende, payed, photos, latitude, longitude, created_at
            ) VALUES (
                :dossier_id, :type_dossier, :date_infraction, :lieu, :type_infraction,
                :description, :reference_loi, :amende, :payed, :photos, :latitude, :longitude, NOW()
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
            
            // Gérer les coordonnées géographiques
            $latitude = !empty($data['latitude']) ? floatval($data['latitude']) : null;
            $longitude = !empty($data['longitude']) ? floatval($data['longitude']) : null;
            $stmt->bindParam(':latitude', $latitude);
            $stmt->bindParam(':longitude', $longitude);
            
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
     * Create simple PDF file using basic PDF structure
     */
    private function createSimplePdf($html, $filepath, $contravention) {
        // Create a basic PDF structure
        $pdf_content = $this->generateBasicPdf($contravention);
        
        // Write to file
        file_put_contents($filepath, $pdf_content);
    }
    
    /**
     * Generate basic PDF content using wkhtmltopdf or fallback to HTML
     */
    private function generateBasicPdf($contravention) {
        // Try to use wkhtmltopdf if available, otherwise create HTML file
        $html = $this->generatePdfHtml($contravention);
        
        // Check if wkhtmltopdf is available
        $wkhtmltopdf = shell_exec('which wkhtmltopdf 2>/dev/null');
        
        if (!empty($wkhtmltopdf)) {
            // Use wkhtmltopdf to convert HTML to PDF
            $tempHtml = tempnam(sys_get_temp_dir(), 'contravention_') . '.html';
            file_put_contents($tempHtml, $html);
            
            $tempPdf = tempnam(sys_get_temp_dir(), 'contravention_') . '.pdf';
            $command = "wkhtmltopdf --page-size A4 --margin-top 20mm --margin-bottom 20mm --margin-left 15mm --margin-right 15mm '$tempHtml' '$tempPdf' 2>/dev/null";
            
            exec($command, $output, $return_code);
            
            if ($return_code === 0 && file_exists($tempPdf)) {
                $pdfContent = file_get_contents($tempPdf);
                unlink($tempHtml);
                unlink($tempPdf);
                return $pdfContent;
            }
            
            // Clean up temp files if command failed
            if (file_exists($tempHtml)) unlink($tempHtml);
            if (file_exists($tempPdf)) unlink($tempPdf);
        }
        
        // Fallback: Create a minimal valid PDF
        return $this->createMinimalPdf($contravention);
    }
    
    /**
     * Create a minimal valid PDF structure
     */
    private function createMinimalPdf($contravention) {
        $content = "BUREAU DE CONTROLE ROUTIER\n\n";
        $content .= "CONTRAVENTION N° " . ($contravention['id'] ?? 'N/A') . "\n\n";
        $content .= "Date: " . ($contravention['date_infraction'] ?? 'N/A') . "\n";
        $content .= "Lieu: " . ($contravention['lieu'] ?? 'N/A') . "\n";
        $content .= "Type: " . ($contravention['type_infraction'] ?? 'N/A') . "\n";
        $content .= "Description: " . ($contravention['description'] ?? 'N/A') . "\n";
        $content .= "Ref. loi: " . ($contravention['reference_loi'] ?? 'N/A') . "\n";
        $content .= "Amende: " . ($contravention['amende'] ?? 'N/A') . " FC\n";
        $content .= "Statut: " . ($contravention['payed'] === 'oui' ? 'Payee' : 'Non payee') . "\n";
        
        if (!empty($contravention['latitude']) && !empty($contravention['longitude'])) {
            $content .= "\nCoordonnees GPS:\n";
            $content .= "Lat: " . $contravention['latitude'] . "\n";
            $content .= "Lng: " . $contravention['longitude'] . "\n";
        }
        
        // Create a minimal PDF structure
        $pdf = "%PDF-1.4\n";
        $pdf .= "1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n";
        $pdf .= "2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n";
        $pdf .= "3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj\n";
        
        // Escape content for PDF
        $escapedContent = str_replace(['(', ')', '\\'], ['\\(', '\\)', '\\\\'], $content);
        $stream = "BT /F1 12 Tf 50 750 Td ($escapedContent) Tj ET";
        $streamLength = strlen($stream);
        
        $pdf .= "4 0 obj<</Length $streamLength>>stream\n$stream\nendstream\nendobj\n";
        $pdf .= "5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj\n";
        
        $xrefPos = strlen($pdf);
        $pdf .= "xref\n0 6\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000251 00000 n \n0000000340 00000 n \n";
        $pdf .= "trailer<</Size 6/Root 1 0 R>>\nstartxref\n$xrefPos\n%%EOF";
        
        return $pdf;
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

    /**
     * Update contravention (superadmin only)
     */
    public function update($data) {
        try {
            // Vérifier que l'ID est fourni
            if (!isset($data['id']) || empty($data['id'])) {
                return [
                    'success' => false,
                    'message' => 'ID de contravention requis'
                ];
            }

            $contraventionId = (int)$data['id'];

            // Vérifier que la contravention existe
            $checkQuery = "SELECT * FROM {$this->table} WHERE id = :id";
            $checkStmt = $this->db->prepare($checkQuery);
            $checkStmt->bindParam(':id', $contraventionId);
            $checkStmt->execute();
            
            $existingContravention = $checkStmt->fetch(PDO::FETCH_ASSOC);
            if (!$existingContravention) {
                return [
                    'success' => false,
                    'message' => 'Contravention introuvable'
                ];
            }

            // Vérifier si les colonnes latitude/longitude existent, sinon les ajouter
            try {
                $checkLat = $this->db->query("SHOW COLUMNS FROM {$this->table} LIKE 'latitude'");
                $checkLng = $this->db->query("SHOW COLUMNS FROM {$this->table} LIKE 'longitude'");
                
                if ($checkLat->rowCount() == 0 || $checkLng->rowCount() == 0) {
                    $this->db->exec("ALTER TABLE {$this->table} 
                        ADD COLUMN latitude DECIMAL(10, 8) DEFAULT NULL,
                        ADD COLUMN longitude DECIMAL(11, 8) DEFAULT NULL");
                }
            } catch (Exception $e) {
                error_log("Warning: Could not add lat/lng columns: " . $e->getMessage());
            }

            // Préparer la requête de mise à jour
            $updateQuery = "UPDATE {$this->table} SET 
                date_infraction = :date_infraction,
                lieu = :lieu,
                type_infraction = :type_infraction,
                description = :description,
                reference_loi = :reference_loi,
                amende = :amende,
                payed = :payed,
                latitude = :latitude,
                longitude = :longitude,
                updated_at = NOW()
                WHERE id = :id";

            $stmt = $this->db->prepare($updateQuery);
            
            // Bind parameters
            $stmt->bindParam(':id', $contraventionId);
            $stmt->bindParam(':date_infraction', $data['date_infraction']);
            $stmt->bindParam(':lieu', $data['lieu']);
            $stmt->bindParam(':type_infraction', $data['type_infraction']);
            $stmt->bindParam(':description', $data['description']);
            $stmt->bindParam(':reference_loi', $data['reference_loi']);
            $stmt->bindParam(':amende', $data['amende']);
            
            $payed = $data['payed'] ?? '0';
            $stmt->bindParam(':payed', $payed);
            
            // Gérer les coordonnées géographiques
            $latitude = !empty($data['latitude']) ? floatval($data['latitude']) : null;
            $longitude = !empty($data['longitude']) ? floatval($data['longitude']) : null;
            $stmt->bindParam(':latitude', $latitude);
            $stmt->bindParam(':longitude', $longitude);

            if ($stmt->execute()) {
                // Préparer les données pour le log
                $changes = [];
                $fields = ['date_infraction', 'lieu', 'type_infraction', 'description', 'reference_loi', 'amende', 'payed', 'latitude', 'longitude'];
                
                foreach ($fields as $field) {
                    $oldValue = $existingContravention[$field] ?? null;
                    $newValue = $data[$field] ?? null;
                    
                    // Conversion spéciale pour les coordonnées
                    if ($field === 'latitude' || $field === 'longitude') {
                        $newValue = !empty($newValue) ? floatval($newValue) : null;
                    }
                    
                    if ($oldValue != $newValue) {
                        $changes[$field] = [
                            'old' => $oldValue,
                            'new' => $newValue
                        ];
                    }
                }

                return [
                    'success' => true,
                    'message' => 'Contravention mise à jour avec succès',
                    'id' => $contraventionId,
                    'changes' => $changes
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
}
?>
