<?php
require_once __DIR__ . '/../config/database.php';

/**
 * Contrôleur pour la génération de PDF d'avis de recherche
 */
class AvisRecherchePdfController {
    private $db;
    
    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }
    
    /**
     * Générer le PDF pour un avis de recherche
     */
    public function generatePdf($avisId) {
        try {
            // Récupérer l'avis de recherche avec les détails de la cible
            $avis = $this->getAvisWithDetails($avisId);
            
            if (!$avis) {
                return [
                    'success' => false,
                    'message' => 'Avis de recherche introuvable'
                ];
            }
            
            // Créer le dossier uploads si nécessaire
            $uploadsDir = __DIR__ . '/../uploads/avis_recherche_pdf';
            if (!is_dir($uploadsDir)) {
                mkdir($uploadsDir, 0777, true);
            }
            
            // Générer le nom du fichier PDF
            $filename = 'avis_recherche_' . $avisId . '_' . date('Y-m-d_H-i-s') . '.pdf';
            $filepath = $uploadsDir . '/' . $filename;
            
            // Générer le HTML du PDF
            $html = $this->generatePdfHtml($avis);
            
            // Générer le PDF
            $this->createPdf($html, $filepath);
            
            // Mettre à jour le chemin du PDF dans la base de données
            // Retourner le chemin sans /api/ car Flutter ajoute le baseUrl qui contient déjà /api/
            $pdfUrl = 'uploads/avis_recherche_pdf/' . $filename;
            $this->updatePdfPath($avisId, $pdfUrl);
            
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
     * Récupérer l'avis de recherche avec tous les détails
     */
    private function getAvisWithDetails($avisId) {
        $query = "SELECT ar.*, 
                    CASE 
                        WHEN ar.cible_type = 'particuliers' THEN 
                            JSON_OBJECT(
                                'nom', p.nom,
                                'gsm', p.gsm,
                                'adresse', p.adresse,
                                'date_naissance', p.date_naissance,
                                'photo', p.photo
                            )
                        WHEN ar.cible_type = 'vehicule_plaque' THEN 
                            JSON_OBJECT(
                                'plaque', vp.plaque,
                                'marque', vp.marque,
                                'modele', vp.modele,
                                'couleur', vp.couleur,
                                'annee', vp.annee
                            )
                    END as cible_details
                  FROM avis_recherche ar
                  LEFT JOIN particuliers p ON ar.cible_type = 'particuliers' AND ar.cible_id = p.id
                  LEFT JOIN vehicule_plaque vp ON ar.cible_type = 'vehicule_plaque' AND ar.cible_id = vp.id
                  WHERE ar.id = :id";
        
        $stmt = $this->db->prepare($query);
        $stmt->bindParam(':id', $avisId);
        $stmt->execute();
        
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($result && $result['cible_details']) {
            $result['cible_details'] = json_decode($result['cible_details'], true);
        }
        
        return $result;
    }
    
    /**
     * Générer le HTML pour le PDF
     */
    private function generatePdfHtml($avis) {
        $isParticulier = $avis['cible_type'] === 'particuliers';
        $cible = $avis['cible_details'];
        $images = !empty($avis['images']) ? json_decode($avis['images'], true) : [];
        
        // Chemins des assets
        $drapeauPath = __DIR__ . '/../assets/images/drapeau.png';
        $logoPath = __DIR__ . '/../assets/images/logo.png';
        
        // Convertir images en base64 pour l'inclusion dans le PDF
        $drapeauBase64 = $this->imageToBase64($drapeauPath);
        $logoBase64 = $this->imageToBase64($logoPath);
        
        // Déterminer la couleur selon le niveau
        $niveauColor = match($avis['niveau']) {
            'faible' => '#28a745',
            'moyen' => '#ff9800',
            'élevé' => '#dc3545',
            default => '#ff9800'
        };
        
        $html = '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Avis de Recherche #' . $avis['id'] . '</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: "Helvetica Neue", Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            box-shadow: 0 10px 50px rgba(0,0,0,0.3);
            border-radius: 15px;
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: white;
            padding: 30px;
            position: relative;
            text-align: center;
        }
        
        .header-flags {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        
        .flag-logo {
            width: 80px;
            height: auto;
        }
        
        .header h1 {
            font-size: 36px;
            text-transform: uppercase;
            letter-spacing: 3px;
            margin: 20px 0;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        
        .header .subtitle {
            font-size: 18px;
            opacity: 0.9;
            margin-bottom: 10px;
        }
        
        .alert-banner {
            background: ' . $niveauColor . ';
            color: white;
            padding: 15px 30px;
            text-align: center;
            font-size: 20px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 2px;
            box-shadow: 0 4px 10px rgba(0,0,0,0.2);
        }
        
        .content {
            padding: 30px;
        }
        
        .avis-number {
            text-align: center;
            font-size: 14px;
            color: #666;
            margin-bottom: 20px;
        }
        
        .avis-number strong {
            color: #1e3c72;
            font-size: 18px;
        }
        
        .section {
            margin-bottom: 30px;
        }
        
        .section-title {
            background: #f8f9fa;
            padding: 12px 20px;
            border-left: 5px solid #1e3c72;
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 15px;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .info-item {
            padding: 12px;
            background: #f8f9fa;
            border-radius: 8px;
            border-left: 3px solid #1e3c72;
        }
        
        .info-item label {
            display: block;
            font-weight: bold;
            color: #555;
            font-size: 12px;
            text-transform: uppercase;
            margin-bottom: 5px;
        }
        
        .info-item .value {
            color: #333;
            font-size: 16px;
        }
        
        .motif-box {
            background: #fff3cd;
            border: 2px solid #ffc107;
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
        }
        
        .motif-box h3 {
            color: #856404;
            margin-bottom: 10px;
            font-size: 16px;
        }
        
        .motif-box p {
            color: #333;
            line-height: 1.6;
            font-size: 14px;
        }
        
        .images-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-top: 15px;
        }
        
        .image-box {
            border: 2px solid #ddd;
            border-radius: 8px;
            overflow: hidden;
            height: 200px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #f5f5f5;
        }
        
        .image-box img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        
        .contact-warning {
            background: #dc3545;
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            margin-top: 30px;
        }
        
        .contact-warning h3 {
            font-size: 20px;
            margin-bottom: 10px;
        }
        
        .contact-warning p {
            font-size: 16px;
            margin: 5px 0;
        }
        
        .footer {
            background: #1e3c72;
            color: white;
            padding: 20px;
            text-align: center;
        }
        
        .footer p {
            margin: 5px 0;
            font-size: 12px;
        }
        
        .watermark {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%) rotate(-45deg);
            font-size: 120px;
            color: rgba(0,0,0,0.05);
            font-weight: bold;
            z-index: 0;
            pointer-events: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->';
        
        $html .= '
        <div class="header">
            <div class="header-flags">';
        
        if ($drapeauBase64) {
            $html .= '<img src="' . $drapeauBase64 . '" alt="Drapeau" class="flag-logo">';
        }
        
        $html .= '<div style="text-align: center; flex: 1;">
                    <div class="subtitle">République Démocratique du Congo</div>
                    <h1>AVIS DE RECHERCHE</h1>
                    <div class="subtitle">Bureau de Contrôle Routier</div>
                </div>';
        
        if ($logoBase64) {
            $html .= '<img src="' . $logoBase64 . '" alt="Logo" class="flag-logo">';
        }
        
        $html .= '</div>
        </div>
        
        <div class="alert-banner">
            Niveau de Priorité: ' . strtoupper($avis['niveau']) . '
        </div>
        
        <div class="content">
            <div class="watermark">URGENT</div>
            
            <div class="avis-number">
                <strong>Avis N° ' . str_pad($avis['id'], 6, '0', STR_PAD_LEFT) . '</strong><br>
                Émis le ' . date('d/m/Y', strtotime($avis['created_at'])) . ' par ' . htmlspecialchars($avis['created_by']) . '
            </div>';
        
        // Section Particulier ou Véhicule
        if ($isParticulier) {
            $html .= '
            <div class="section">
                <div class="section-title">👤 PERSONNE RECHERCHÉE</div>
                <div class="info-grid">
                    <div class="info-item">
                        <label>Nom complet</label>
                        <div class="value">' . htmlspecialchars($cible['nom'] ?? 'N/A') . '</div>
                    </div>
                    <div class="info-item">
                        <label>Téléphone</label>
                        <div class="value">' . htmlspecialchars($cible['gsm'] ?? 'N/A') . '</div>
                    </div>
                    <div class="info-item">
                        <label>Date de naissance</label>
                        <div class="value">' . ($cible['date_naissance'] ? date('d/m/Y', strtotime($cible['date_naissance'])) : 'N/A') . '</div>
                    </div>
                    <div class="info-item">
                        <label>Adresse</label>
                        <div class="value">' . htmlspecialchars($cible['adresse'] ?? 'N/A') . '</div>
                    </div>
                </div>
            </div>';
        } else {
            $html .= '
            <div class="section">
                <div class="section-title">🚗 VÉHICULE RECHERCHÉ</div>
                <div class="info-grid">
                    <div class="info-item">
                        <label>Plaque d\'immatriculation</label>
                        <div class="value" style="font-size: 20px; font-weight: bold; color: #dc3545;">' . htmlspecialchars($cible['plaque'] ?? 'N/A') . '</div>
                    </div>
                    <div class="info-item">
                        <label>Marque et Modèle</label>
                        <div class="value">' . htmlspecialchars($cible['marque'] ?? 'N/A') . ' ' . htmlspecialchars($cible['modele'] ?? 'N/A') . '</div>
                    </div>
                    <div class="info-item">
                        <label>Couleur</label>
                        <div class="value">' . htmlspecialchars($cible['couleur'] ?? 'N/A') . '</div>
                    </div>
                    <div class="info-item">
                        <label>Année</label>
                        <div class="value">' . htmlspecialchars($cible['annee'] ?? 'N/A') . '</div>
                    </div>';
            
            if (!empty($avis['numero_chassis'])) {
                $html .= '
                    <div class="info-item" style="grid-column: 1 / -1;">
                        <label>Numéro de châssis</label>
                        <div class="value" style="font-family: monospace; font-size: 14px;">' . htmlspecialchars($avis['numero_chassis']) . '</div>
                    </div>';
            }
            
            $html .= '
                </div>
            </div>';
        }
        
        // Motif de la recherche
        $html .= '
            <div class="motif-box">
                <h3>📋 MOTIF DE LA RECHERCHE</h3>
                <p>' . nl2br(htmlspecialchars($avis['motif'])) . '</p>
            </div>';
        
        // Images si disponibles
        if (!empty($images) && is_array($images)) {
            $html .= '
            <div class="section">
                <div class="section-title">📸 PHOTOS</div>
                <div class="images-grid">';
            
            foreach ($images as $imagePath) {
                $fullPath = __DIR__ . '/../../' . $imagePath;
                if (file_exists($fullPath)) {
                    $imageBase64 = $this->imageToBase64($fullPath);
                    if ($imageBase64) {
                        $html .= '<div class="image-box"><img src="' . $imageBase64 . '" alt="Photo"></div>';
                    }
                }
            }
            
            $html .= '
                </div>
            </div>';
        }
        
        // Avertissement de contact
        $html .= '
            <div class="contact-warning">
                <h3>⚠️ INFORMATION IMPORTANTE</h3>
                <p>Si vous avez des informations concernant ' . ($isParticulier ? 'cette personne' : 'ce véhicule') . ',</p>
                <p>veuillez contacter immédiatement le Bureau de Contrôle Routier</p>
                <p><strong>Téléphone: +243 XXX XXX XXX</strong></p>
                <p style="font-size: 12px; margin-top: 10px;">Ne tentez pas d\'intervenir vous-même</p>
            </div>
        </div>
        
        <div class="footer">
            <p><strong>Bureau de Contrôle Routier - République Démocratique du Congo</strong></p>
            <p>Avenue de la Justice, Kinshasa - RDC</p>
            <p>Email: contact@controle-routier-rdc.gov.cd</p>
            <p style="margin-top: 10px; font-size: 10px;">Document officiel - Toute reproduction non autorisée est interdite</p>
        </div>
    </div>
</body>
</html>';
        
        return $html;
    }
    
    /**
     * Convertir une image en base64 pour inclusion dans le PDF
     */
    private function imageToBase64($imagePath) {
        if (!file_exists($imagePath)) {
            return null;
        }
        
        $imageData = file_get_contents($imagePath);
        $base64 = base64_encode($imageData);
        $mimeType = mime_content_type($imagePath);
        
        return 'data:' . $mimeType . ';base64,' . $base64;
    }
    
    /**
     * Créer le PDF à partir du HTML
     */
    private function createPdf($html, $filepath) {
        // Create PDF content using the same logic as contraventions
        $pdf_content = $this->generateBasicPdf($html, $filepath);
        
        // Write to file
        file_put_contents($filepath, $pdf_content);
        return true;
    }
    
    /**
     * Generate basic PDF content using wkhtmltopdf or fallback to minimal PDF
     */
    private function generateBasicPdf($html, $filepath) {
        // Check if wkhtmltopdf is available
        $wkhtmltopdf = shell_exec('which wkhtmltopdf 2>/dev/null');
        
        if (!empty(trim($wkhtmltopdf))) {
            // Use wkhtmltopdf to convert HTML to PDF
            $tempHtml = tempnam(sys_get_temp_dir(), 'avis_') . '.html';
            file_put_contents($tempHtml, $html);
            
            $tempPdf = tempnam(sys_get_temp_dir(), 'avis_') . '.pdf';
            $command = "wkhtmltopdf --page-size A4 --margin-top 10mm --margin-bottom 10mm --margin-left 10mm --margin-right 10mm --enable-local-file-access '" . $tempHtml . "' '" . $tempPdf . "' 2>/dev/null";
            
            exec($command, $output, $return_code);
            
            if ($return_code === 0 && file_exists($tempPdf)) {
                $pdfContent = file_get_contents($tempPdf);
                if (file_exists($tempHtml)) unlink($tempHtml);
                if (file_exists($tempPdf)) unlink($tempPdf);
                return $pdfContent;
            }
            
            // Clean up temp files if command failed
            if (file_exists($tempHtml)) unlink($tempHtml);
            if (file_exists($tempPdf)) unlink($tempPdf);
        }
        
        // Fallback: return the HTML as is (will be saved as .pdf file)
        // This allows the file to be created even if wkhtmltopdf is not available
        return $html;
    }
    
    /**
     * Mettre à jour le chemin du PDF dans la base de données
     */
    private function updatePdfPath($avisId, $pdfPath) {
        // Vérifier si la colonne existe
        $checkColumn = $this->db->query("SHOW COLUMNS FROM avis_recherche LIKE 'pdf_path'");
        if ($checkColumn->rowCount() == 0) {
            $this->db->exec("ALTER TABLE avis_recherche ADD COLUMN pdf_path TEXT NULL");
        }
        
        $query = "UPDATE avis_recherche SET pdf_path = :pdf_path WHERE id = :id";
        $stmt = $this->db->prepare($query);
        $stmt->bindParam(':pdf_path', $pdfPath);
        $stmt->bindParam(':id', $avisId);
        $stmt->execute();
    }
}
?>
