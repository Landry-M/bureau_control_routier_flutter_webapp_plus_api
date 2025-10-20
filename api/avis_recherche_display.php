<?php
/**
 * Page de prévisualisation d'avis de recherche
 * Récupère les données depuis la base de données et les affiche
 * Paramètres: ?id={avis_id}
 */

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/config/env.php';

$avisId = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($avisId <= 0) {
    http_response_code(400);
    die('<div style="margin:40px;text-align:center;color:red;font-family:Arial;">ID d\'avis de recherche manquant ou invalide</div>');
}

try {
    // Connexion à la base de données
    $database = new Database();
    $pdo = $database->getConnection();
    
    if (!$pdo) {
        throw new Exception('Erreur de connexion à la base de données');
    }
    
    // Récupérer l'avis de recherche avec les informations de la cible
    $stmt = $pdo->prepare("
        SELECT 
            ar.*,
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
        WHERE ar.id = :id
        LIMIT 1
    ");
    
    $stmt->bindParam(':id', $avisId, PDO::PARAM_INT);
    $stmt->execute();
    $avis = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$avis) {
        http_response_code(404);
        die('<div style="margin:40px;text-align:center;color:red;font-family:Arial;">Avis de recherche introuvable</div>');
    }
    
    // Décoder les détails de la cible
    $cible = [];
    if (!empty($avis['cible_details'])) {
        $cible = json_decode($avis['cible_details'], true) ?: [];
    }
    
    // Préparer les images
    $images = [];
    if (!empty($avis['images'])) {
        $imagesJson = json_decode($avis['images'], true);
        if (is_array($imagesJson)) {
            $images = $imagesJson;
        } elseif (is_string($avis['images'])) {
            // Si c'est une chaîne simple, la mettre dans un tableau
            $images = [$avis['images']];
        }
    }
    
} catch (Exception $e) {
    http_response_code(500);
    die('<div style="margin:40px;text-align:center;color:red;font-family:Arial;">Erreur: ' . htmlspecialchars($e->getMessage()) . '</div>');
}

// Déterminer l'URL de base pour les assets
$protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
$baseUrl = $protocol . '://' . $host;

$isParticulier = $avis['cible_type'] === 'particuliers';

// Couleur selon le niveau de priorité
$niveauColor = match($avis['niveau']) {
    'faible' => '#28a745',
    'moyen' => '#ff9800',
    'élevé' => '#dc3545',
    default => '#ff9800'
};

?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Avis de Recherche N° <?= htmlspecialchars($avis['id']) ?></title>
    <style>
        body { background:#f5f6f8; margin:0; padding:20px; font-family: Arial, sans-serif; }
        .actions { text-align:center; margin: 10px 0 20px; }
        .btn { display:inline-block; padding:10px 16px; margin:0 6px; border-radius:4px; border:none; cursor:pointer; font-weight:bold; }
        .btn-primary { background:#00509e; color:#fff; }
        .btn-secondary { background:#6c757d; color:#fff; }
        .paper { background:#fff; max-width:900px; margin:0 auto; padding:0; box-shadow:0 2px 10px rgba(0,0,0,0.08); overflow: hidden; }
        @media print { .actions { display:none; } body { background:#fff; } .paper { box-shadow:none; } }
    </style>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
</head>
<body>

<div class="actions">
    <button id="btn-print" class="btn btn-secondary" onclick="window.print()">Imprimer</button>
    <button id="btn-export" class="btn btn-primary">Exporter PDF</button>
</div>

<div id="paper" class="paper">
    <div class="container" style="padding: 20px;">
        <!-- En-tête -->
        <div class="header" style="position: relative; text-align: center; margin-bottom: 20px; background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); color: white; padding: 30px; border-radius: 10px 10px 0 0;">
            <div class="header-flags" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                <img src="<?= $baseUrl ?>/api/assets/images/drapeau.png" 
                     alt="Drapeau RDC" 
                     style="height: 60px; width: auto; max-width: 80px; object-fit: contain;"
                     onerror="this.style.display='none'">
                
                <div style="flex: 1; text-align: center;">
                    <div style="font-size: 14px; opacity: 0.9;">République Démocratique du Congo</div>
                    <h1 style="font-size: 32px; margin: 10px 0; text-transform: uppercase; letter-spacing: 2px;">AVIS DE RECHERCHE</h1>
                    <div style="font-size: 14px; opacity: 0.9;">Bureau de Contrôle Routier</div>
                </div>
                
                <img src="<?= $baseUrl ?>/api/assets/images/logo.jpg" 
                     alt="Logo BCR" 
                     style="height: 60px; width: auto; max-width: 80px; object-fit: contain;"
                     onerror="this.style.display='none'">
            </div>
        </div>

        <!-- Bannière de niveau de priorité -->
        <div style="background: <?= $niveauColor ?>; color: white; padding: 15px; text-align: center; font-size: 18px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px;">
            Niveau de Priorité: <?= htmlspecialchars(strtoupper($avis['niveau'])) ?>
        </div>

        <!-- Numéro de l'avis -->
        <div style="text-align: center; margin: 20px 0; padding: 15px; background: #f5f5f5;">
            <strong style="font-size: 16px;">Avis N° <?= str_pad($avis['id'], 6, '0', STR_PAD_LEFT) ?></strong><br>
            <span style="font-size: 14px; color: #666;">Émis le <?= date('d/m/Y', strtotime($avis['created_at'])) ?></span>
        </div>

        <!-- Section Personne ou Véhicule recherché -->
        <?php if ($isParticulier): ?>
        <div style="margin-bottom: 25px;">
            <h4 style="background: #f5f5f5; padding: 10px; margin: 0 0 15px 0; border-left: 4px solid #dc3545;">
                👤 PERSONNE RECHERCHÉE
            </h4>
            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px;">
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Nom complet :</label>
                    <input type="text" value="<?= htmlspecialchars($cible['nom'] ?? 'N/A') ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Téléphone :</label>
                    <input type="text" value="<?= htmlspecialchars($cible['gsm'] ?? 'N/A') ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <?php if (!empty($cible['date_naissance'])): ?>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Date de naissance :</label>
                    <input type="text" value="<?= date('d/m/Y', strtotime($cible['date_naissance'])) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <?php endif; ?>
                <div style="<?= empty($cible['date_naissance']) ? 'grid-column: 1 / -1;' : '' ?>">
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Adresse :</label>
                    <input type="text" value="<?= htmlspecialchars($cible['adresse'] ?? 'N/A') ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
            </div>
        </div>
        <?php else: ?>
        <div style="margin-bottom: 25px;">
            <h4 style="background: #f5f5f5; padding: 10px; margin: 0 0 15px 0; border-left: 4px solid #dc3545;">
                🚗 VÉHICULE RECHERCHÉ
            </h4>
            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px;">
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Plaque d'immatriculation :</label>
                    <input type="text" value="<?= htmlspecialchars($cible['plaque'] ?? 'N/A') ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-size: 18px; font-weight: bold; color: #dc3545;" readonly>
                </div>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Marque et Modèle :</label>
                    <input type="text" value="<?= htmlspecialchars(($cible['marque'] ?? 'N/A') . ' ' . ($cible['modele'] ?? '')) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Couleur :</label>
                    <input type="text" value="<?= htmlspecialchars($cible['couleur'] ?? 'N/A') ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Année :</label>
                    <input type="text" value="<?= htmlspecialchars($cible['annee'] ?? 'N/A') ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <?php if (!empty($avis['numero_chassis'])): ?>
                <div style="grid-column: 1 / -1;">
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Numéro de châssis :</label>
                    <input type="text" value="<?= htmlspecialchars($avis['numero_chassis']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-family: monospace; font-size: 14px;" readonly>
                </div>
                <?php endif; ?>
            </div>
        </div>
        <?php endif; ?>

        <!-- Motif de la recherche -->
        <div style="background: #fff3cd; border: 2px solid #ffc107; border-radius: 8px; padding: 20px; margin: 20px 0;">
            <h3 style="color: #856404; margin: 0 0 10px 0; font-size: 16px;">📋 MOTIF DE LA RECHERCHE</h3>
            <p style="margin: 0; line-height: 1.6; font-size: 14px;"><?= nl2br(htmlspecialchars($avis['motif'])) ?></p>
        </div>

        <!-- Photos -->
        <?php if (!empty($images)): ?>
        <div style="margin-bottom: 25px;">
            <h4 style="background: #f5f5f5; padding: 10px; margin: 0 0 15px 0; border-left: 4px solid #00509e;">
                📸 PHOTOS
            </h4>
            <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 15px;">
                <?php foreach ($images as $image): ?>
                    <?php 
                    // Nettoyer et construire l'URL de l'image
                    $imageUrl = trim($image);
                    
                    // Si ce n'est pas déjà une URL complète
                    if (!preg_match('/^https?:\/\//', $imageUrl)) {
                        // Enlever le slash initial s'il existe pour reconstruction propre
                        $imageUrl = ltrim($imageUrl, '/');
                        
                        // Reconstruire le chemin complet
                        // Le chemin sauvegardé est du type: uploads/avis_recherche/file.jpg
                        $imageUrl = $baseUrl . '/api/' . $imageUrl;
                    }
                    ?>
                    <div style="border: 2px solid #ddd; border-radius: 8px; overflow: hidden; height: 150px;">
                        <img src="<?= htmlspecialchars($imageUrl) ?>" 
                             alt="Photo" 
                             style="width: 100%; height: 100%; object-fit: cover;"
                             onerror="this.style.display='none'; this.parentElement.innerHTML='<div style=&quot;display:flex;align-items:center;justify-content:center;height:100%;background:#f0f0f0;color:#999;font-size:12px;&quot;>❌ Image non disponible</div>';">
                    </div>
                <?php endforeach; ?>
            </div>
        </div>
        <?php endif; ?>

        <!-- Avertissement -->
        <div style="background: #dc3545; color: white; padding: 20px; border-radius: 8px; text-align: center; margin-top: 30px;">
            <h3 style="font-size: 18px; margin: 0 0 10px 0;">⚠️ INFORMATION IMPORTANTE</h3>
            <p style="margin: 5px 0;">Si vous avez des informations concernant <?= $isParticulier ? 'cette personne' : 'ce véhicule' ?>,</p>
            <p style="margin: 5px 0;">veuillez contacter immédiatement le Bureau de Contrôle Routier</p>
            <p style="font-size: 12px; margin: 10px 0 0;">Ne tentez pas d'intervenir vous-même</p>
        </div>

        <!-- Pied de page -->
        <div style="margin-top: 30px; padding: 20px; background: #1e3c72; color: white; text-align: center; border-radius: 0 0 10px 10px;">
            <p style="margin: 5px 0;"><strong>Bureau de Contrôle Routier - République Démocratique du Congo</strong></p>
            <p style="margin: 10px 0 0; font-size: 10px;">Document officiel - Toute reproduction non autorisée est interdite</p>
        </div>
    </div>
</div>

<script>
(function(){
    const avisId = <?php echo json_encode($avisId); ?>;

    // Export PDF functionality
    document.getElementById('btn-export').addEventListener('click', async function(){
        const btn = this;
        btn.disabled = true;
        btn.textContent = 'Génération en cours...';
        
        try {
            const el = document.getElementById('paper');
            const target = el.querySelector('.container') || el;
            
            // Generate canvas from HTML
            const canvas = await html2canvas(target, { 
                scale: 2, 
                useCORS: true, 
                allowTaint: true, 
                backgroundColor: '#ffffff',
                logging: false
            });
            
            // Create PDF
            const { jsPDF } = window.jspdf;
            const pdf = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
            const imgData = canvas.toDataURL('image/png');

            const pageWidth = pdf.internal.pageSize.getWidth();
            const imgWidth = pageWidth - 20; // margins
            const imgHeight = canvas.height * imgWidth / canvas.width;
            
            pdf.addImage(imgData, 'PNG', 10, 10, imgWidth, imgHeight);

            // Download PDF locally
            pdf.save(`avis_recherche_${avisId}.pdf`);
            
            alert('PDF téléchargé avec succès !');
        } catch (err) {
            console.error(err);
            alert('Erreur lors de la génération du PDF: ' + err.message);
        } finally {
            btn.disabled = false;
            btn.textContent = 'Exporter PDF';
        }
    });
})();
</script>
</body>
</html>
