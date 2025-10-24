<?php
/**
 * Page de prévisualisation de contravention
 * Récupère les données depuis la base de données et les affiche
 * Paramètres: ?id={contravention_id}
 */

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/config/env.php';

$cvId = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($cvId <= 0) {
    http_response_code(400);
    die('<div style="margin:40px;text-align:center;color:red;font-family:Arial;">ID de contravention manquant ou invalide</div>');
}

try {
    // Connexion à la base de données
    $database = new Database();
    $pdo = $database->getConnection();
    
    if (!$pdo) {
        throw new Exception('Erreur de connexion à la base de données');
    }
    
    // Récupérer la contravention avec les informations liées
    $stmt = $pdo->prepare("
        SELECT 
            c.*,
            CASE 
                WHEN c.type_dossier = 'particulier' THEN p.nom
                WHEN c.type_dossier = 'entreprise' THEN e.designation
                WHEN c.type_dossier = 'vehicule_plaque' THEN CONCAT('Véhicule ', vp.plaque)
                ELSE 'N/A'
            END as nom_contrevenant,
            CASE 
                WHEN c.type_dossier = 'particulier' THEN p.gsm
                WHEN c.type_dossier = 'entreprise' THEN e.gsm
                ELSE NULL
            END as telephone_contrevenant,
            CASE 
                WHEN c.type_dossier = 'particulier' THEN p.adresse
                WHEN c.type_dossier = 'entreprise' THEN e.siege_social
                ELSE NULL
            END as adresse_contrevenant,
            CASE 
                WHEN c.type_dossier = 'particulier' THEN p.genre
                WHEN c.type_dossier = 'entreprise' THEN NULL
                ELSE NULL
            END as sexe,
            CASE 
                WHEN c.type_dossier = 'particulier' THEN p.date_naissance
                ELSE NULL
            END as date_naissance,
            CASE 
                WHEN c.type_dossier = 'particulier' THEN p.numero_national
                WHEN c.type_dossier = 'entreprise' THEN e.rccm
                ELSE NULL
            END as numero_identite,
            CASE 
                WHEN c.type_dossier = 'particulier' THEN p.email
                WHEN c.type_dossier = 'entreprise' THEN e.email
                ELSE NULL
            END as email,
            vp.plaque as plaque_vehicule,
            vp.marque as marque_vehicule,
            vp.modele as modele_vehicule,
            vp.couleur as couleur_vehicule
        FROM contraventions c
        LEFT JOIN particuliers p ON c.type_dossier = 'particulier' AND c.dossier_id = p.id
        LEFT JOIN entreprises e ON c.type_dossier = 'entreprise' AND c.dossier_id = e.id
        LEFT JOIN vehicule_plaque vp ON (c.type_dossier = 'vehicule_plaque' AND c.dossier_id = vp.id)
        WHERE c.id = :id
        LIMIT 1
    ");
    
    $stmt->bindParam(':id', $cvId, PDO::PARAM_INT);
    $stmt->execute();
    $cv = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$cv) {
        http_response_code(404);
        die('<div style="margin:40px;text-align:center;color:red;font-family:Arial;">Contravention introuvable</div>');
    }
    
    // Préparer les photos
    $photos = [];
    if (!empty($cv['photos'])) {
        // Essayer d'abord de décoder comme JSON
        $photosJson = json_decode($cv['photos'], true);
        if (is_array($photosJson)) {
            $photos = $photosJson;
        } else {
            // Si ce n'est pas du JSON, c'est peut-être séparé par des virgules
            if (is_string($cv['photos']) && strpos($cv['photos'], ',') !== false) {
                $photos = explode(',', $cv['photos']);
                $photos = array_map('trim', $photos); // Enlever les espaces
                $photos = array_filter($photos); // Enlever les éléments vides
                $photos = array_values($photos); // Réindexer
            } elseif (is_string($cv['photos']) && trim($cv['photos']) !== '') {
                // Si c'est une chaîne simple non vide, la mettre dans un tableau
                $photos = [trim($cv['photos'])];
            }
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

// Préparer les données pour l'affichage
$dt = trim((string)($cv['date_infraction'] ?? ''));
$cv_date = '';
$cv_heure = '';
if ($dt !== '') {
    $ts = strtotime($dt);
    if ($ts) {
        $cv_date = date('d/m/Y', $ts);
        $cv_heure = date('H:i', $ts);
    }
}

// Construire le payload avec les données déjà récupérées
$payload = [
    'type_dossier' => (string)($cv['type_dossier'] ?? ''),
    'numero_contravention' => (string)($cv['id'] ?? ''),
    'nom_prenom' => (string)($cv['nom_contrevenant'] ?? ''),
    'sexe' => strtolower((string)($cv['sexe'] ?? '')),
    'date_naissance' => (string)($cv['date_naissance'] ?? ''),
    'numero_identite' => (string)($cv['numero_identite'] ?? ''),
    'adresse' => (string)($cv['adresse_contrevenant'] ?? ''),
    'telephone' => (string)($cv['telephone_contrevenant'] ?? ''),
    'email' => (string)($cv['email'] ?? ''),
    'marque_vehicule' => (string)($cv['marque_vehicule'] ?? ''),
    'immatriculation' => (string)($cv['plaque_vehicule'] ?? ''),
    'couleur_vehicule' => (string)($cv['couleur_vehicule'] ?? ''),
    'modele_vehicule' => (string)($cv['modele_vehicule'] ?? ''),
    'date_infraction' => $cv_date,
    'heure_infraction' => $cv_heure,
    'lieu_infraction' => (string)($cv['lieu'] ?? ''),
    'type_infraction' => (string)($cv['type_infraction'] ?? ''),
    'description_infraction' => (string)($cv['description'] ?? ''),
    'montant_amende' => (string)($cv['amende'] ?? ''),
    'reference_legale' => (string)($cv['reference_loi'] ?? ''),
    'payed' => (string)($cv['payed'] ?? 'non'),
    'observations' => '',
    'latitude' => (string)($cv['latitude'] ?? ''),
    'longitude' => (string)($cv['longitude'] ?? ''),
];

?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Prévisualisation Contravention</title>
    <style>
        body { background:#f5f6f8; margin:0; padding:20px; font-family: Arial, sans-serif; }
        .actions { text-align:center; margin: 10px 0 20px; }
        .btn { display:inline-block; padding:10px 16px; margin:0 6px; border-radius:4px; border:none; cursor:pointer; font-weight:bold; }
        .btn-primary { background:#00509e; color:#fff; }
        .btn-secondary { background:#6c757d; color:#fff; }
        .paper { background:#fff; max-width:900px; margin:0 auto; padding:20px; box-shadow:0 2px 10px rgba(0,0,0,0.08); }
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
    <div class="container" style="padding: 30px;">
        <!-- En-tête -->
        <div class="header" style="position: relative; text-align: center; margin-bottom: 30px; border-bottom: 3px solid #00509e; padding: 20px 0 20px 0;">
            <!-- Drapeau à gauche -->
            <img src="<?= $baseUrl ?>/api/assets/images/drapeau.png" 
                 alt="Drapeau RDC" 
                 style="position: absolute; left: 0; top: 10px; height: 80px; width: auto; max-width: 80px; object-fit: contain;"
                 onerror="this.style.display='none'">
            
            <!-- Logo à droite -->
            <img src="<?= $baseUrl ?>/api/assets/images/logo.jpg" 
                 alt="Logo BCR" 
                 style="position: absolute; right: 0; top: 10px; height: 80px; width: auto; max-width: 80px; object-fit: contain;"
                 onerror="this.style.display='none'">
            
            <div style="margin: 0 100px;">
                <h1 style="color: #00509e; margin: 0; font-size: 28px;">RÉPUBLIQUE DÉMOCRATIQUE DU CONGO</h1>
                <h2 style="color: #333; margin: 10px 0; font-size: 22px;">BUREAU DE CONTRÔLE ROUTIER</h2>
                <h3 style="color: #d32f2f; margin: 10px 0; font-size: 20px;">PROCÈS-VERBAL DE CONTRAVENTION</h3>
                <p style="margin: 10px 0; font-size: 16px; font-weight: bold;">N° <?= htmlspecialchars($payload['numero_contravention']) ?></p>
            </div>
        </div>

        <!-- Section Contrevenant -->
        <?php if ($payload['type_dossier'] !== 'vehicule_plaque'): ?>
        <div id="section-contrevenant" style="margin-bottom: 25px;">
            <h4 style="background: #f5f5f5; padding: 10px; margin: 0 0 15px 0; border-left: 4px solid #00509e;">
                📋 INFORMATIONS DU CONTREVENANT
            </h4>
            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px;">
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">
                        <?= $payload['type_dossier'] === 'entreprise' ? 'Désignation :' : 'Nom et Prénom :' ?>
                    </label>
                    <input type="text" name="nom_prenom" value="<?= htmlspecialchars($payload['nom_prenom']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                
                <?php if ($payload['type_dossier'] === 'particulier' && !empty($payload['sexe'])): ?>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Sexe :</label>
                    <div style="padding: 8px;">
                        <label style="margin-right: 15px;">
                            <input type="radio" name="sexe" value="masculin" <?= (strpos(strtolower($payload['sexe']), 'm') === 0) ? 'checked' : '' ?> disabled> Masculin
                        </label>
                        <label>
                            <input type="radio" name="sexe" value="feminin" <?= (strpos(strtolower($payload['sexe']), 'f') === 0) ? 'checked' : '' ?> disabled> Féminin
                        </label>
                    </div>
                </div>
                <?php endif; ?>
                
                <?php if (!empty($payload['date_naissance'])): ?>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Date de naissance :</label>
                    <input type="text" name="date_naissance" value="<?= htmlspecialchars($payload['date_naissance']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <?php endif; ?>
                
                <?php if (!empty($payload['numero_identite'])): ?>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">
                        <?= $payload['type_dossier'] === 'entreprise' ? 'RCCM :' : 'N° Carte d\'identité :' ?>
                    </label>
                    <input type="text" name="numero_identite" value="<?= htmlspecialchars($payload['numero_identite']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <?php endif; ?>
                
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Adresse :</label>
                    <input type="text" name="adresse" value="<?= htmlspecialchars($payload['adresse']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Téléphone :</label>
                    <input type="text" name="telephone" value="<?= htmlspecialchars($payload['telephone']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                
                <?php if (!empty($payload['email'])): ?>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Email :</label>
                    <input type="text" name="email" value="<?= htmlspecialchars($payload['email']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <?php endif; ?>
            </div>
        </div>
        <?php endif; ?>

        <!-- Section Véhicule -->
        <?php if ($payload['type_dossier'] === 'vehicule_plaque' || !empty($payload['marque_vehicule']) || !empty($payload['immatriculation'])): ?>
        <div style="margin-bottom: 25px;">
            <h4 style="background: #f5f5f5; padding: 10px; margin: 0 0 15px 0; border-left: 4px solid #00509e;">
                🚗 INFORMATIONS DU VÉHICULE <?= $payload['type_dossier'] === 'vehicule_plaque' ? '(CONTREVENANT)' : '' ?>
            </h4>
            <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px;">
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Plaque d'immatriculation :</label>
                    <input type="text" name="immatriculation" value="<?= htmlspecialchars($payload['immatriculation']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-weight: bold; font-size: 16px; color: #d32f2f;" readonly>
                </div>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Marque :</label>
                    <input type="text" name="marque_vehicule" value="<?= htmlspecialchars($payload['marque_vehicule']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Couleur :</label>
                    <input type="text" name="couleur_vehicule" value="<?= htmlspecialchars($payload['couleur_vehicule']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <?php if (!empty($payload['modele_vehicule'])): ?>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Modèle :</label>
                    <input type="text" name="modele_vehicule" value="<?= htmlspecialchars($payload['modele_vehicule']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <?php endif; ?>
            </div>
        </div>
        <?php endif; ?>

        <!-- Section Infraction -->
        <div style="margin-bottom: 25px;">
            <h4 style="background: #f5f5f5; padding: 10px; margin: 0 0 15px 0; border-left: 4px solid #d32f2f;">
                ⚠️ DÉTAILS DE L'INFRACTION
            </h4>
            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-bottom: 15px;">
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Date de l'infraction :</label>
                    <input type="text" name="date_infraction" value="<?= htmlspecialchars($payload['date_infraction']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Heure :</label>
                    <input type="text" name="heure_infraction" value="<?= htmlspecialchars($payload['heure_infraction']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
            </div>
            <div style="margin-bottom: 15px;">
                <label style="font-weight: bold; display: block; margin-bottom: 5px;">Lieu de l'infraction :</label>
                <input type="text" name="lieu_infraction" value="<?= htmlspecialchars($payload['lieu_infraction']) ?>" 
                       style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
            </div>
            <?php if (!empty($payload['type_infraction'])): ?>
            <div style="margin-bottom: 15px;">
                <label style="font-weight: bold; display: block; margin-bottom: 5px;">Type d'infraction :</label>
                <input type="text" value="<?= htmlspecialchars($payload['type_infraction']) ?>" 
                       style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
            </div>
            <?php endif; ?>
            <div style="margin-bottom: 15px;">
                <label style="font-weight: bold; display: block; margin-bottom: 5px;">Description de l'infraction :</label>
                <textarea name="description_infraction" rows="4" 
                          style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly><?= htmlspecialchars($payload['description_infraction']) ?></textarea>
            </div>
            
            <?php if (!empty($payload['latitude']) && !empty($payload['longitude'])): ?>
            <div style="background: #e3f2fd; border: 2px solid #2196f3; border-radius: 8px; padding: 15px; margin-top: 15px;">
                <h5 style="margin: 0 0 10px 0; color: #1976d2; font-size: 14px;">📍 Coordonnées géographiques</h5>
                <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px;">
                    <div>
                        <strong>Latitude :</strong> <?= htmlspecialchars($payload['latitude']) ?>
                    </div>
                    <div>
                        <strong>Longitude :</strong> <?= htmlspecialchars($payload['longitude']) ?>
                    </div>
                </div>
            </div>
            <?php endif; ?>
        </div>

        <!-- Section Sanction -->
        <div style="margin-bottom: 25px;">
            <h4 style="background: #f5f5f5; padding: 10px; margin: 0 0 15px 0; border-left: 4px solid #ff9800;">
                💰 SANCTION
            </h4>
            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px;">
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Montant de l'amende (FC) :</label>
                    <input type="text" name="montant_amende" value="<?= number_format($payload['montant_amende'], 0, ',', ' ') ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-size: 18px; font-weight: bold; color: #d32f2f;" readonly>
                </div>
                <div>
                    <label style="font-weight: bold; display: block; margin-bottom: 5px;">Référence légale :</label>
                    <input type="text" name="reference_legale" value="<?= htmlspecialchars($payload['reference_legale']) ?>" 
                           style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" readonly>
                </div>
            </div>
            <div style="margin-top: 15px;">
                <label style="font-weight: bold; display: block; margin-bottom: 5px;">Statut de paiement :</label>
                <span style="display: inline-block; padding: 8px 16px; border-radius: 20px; font-weight: bold; 
                             <?= strtolower($payload['payed']) === 'oui' ? 'background: #4caf50; color: white;' : 'background: #f44336; color: white;' ?>">
                    <?= strtolower($payload['payed']) === 'oui' ? '✓ Payée' : '✗ Non payée' ?>
                </span>
            </div>
        </div>

        <!-- Photos -->
        <?php if (!empty($photos)): ?>
        <div class="photo-section" style="margin-bottom: 25px;">
            <h4 style="background: #f5f5f5; padding: 10px; margin: 0 0 15px 0; border-left: 4px solid #00509e;">
                📸 PHOTOS DE L'INFRACTION
            </h4>
            <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 15px;">
                <?php foreach ($photos as $photo): ?>
                    <?php 
                    // Nettoyer et construire l'URL de l'image
                    $photoUrl = trim($photo);
                    
                    // Si ce n'est pas déjà une URL complète
                    if (!preg_match('/^https?:\/\//', $photoUrl)) {
                        // Enlever le slash initial s'il existe pour reconstruction propre
                        $photoUrl = ltrim($photoUrl, '/');
                        
                        // Vérifier si le chemin contient déjà 'api/'
                        if (!preg_match('/^api\//', $photoUrl)) {
                            // Le chemin sauvegardé est du type: uploads/contraventions/file.jpg
                            $photoUrl = $baseUrl . '/api/' . $photoUrl;
                        } else {
                            // Le chemin contient déjà api/, juste ajouter le baseUrl
                            $photoUrl = $baseUrl . '/' . $photoUrl;
                        }
                    }
                    ?>
                    <div style="border: 1px solid #ddd; border-radius: 4px; overflow: hidden;">
                        <img src="<?= htmlspecialchars($photoUrl) ?>" 
                             alt="Photo de l'infraction" 
                             style="width: 100%; height: 150px; object-fit: cover;"
                             onerror="this.parentElement.style.display='none'">
                    </div>
                <?php endforeach; ?>
            </div>
        </div>
        <?php endif; ?>

        <!-- Observations -->
        <div style="margin-bottom: 25px;">
            <h4 style="background: #f5f5f5; padding: 10px; margin: 0 0 15px 0; border-left: 4px solid #607d8b;">
                📝 OBSERVATIONS
            </h4>
            <textarea name="observations" rows="3" 
                      style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" 
                      placeholder="Observations complémentaires..." readonly></textarea>
        </div>

        <!-- Pied de page -->
        <div style="margin-top: 40px; padding-top: 20px; border-top: 2px solid #ddd; text-align: center;">
            <p style="margin: 5px 0; color: #666;">Date d'impression : <?= date('d/m/Y H:i') ?></p>
            <p style="margin: 5px 0; color: #666; font-size: 12px;">
                Document généré automatiquement par le Bureau de Contrôle Routier
            </p>
        </div>
    </div>
</div>

<script>
(function(){
    const cvId = <?php echo json_encode($cvId); ?>;

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
            pdf.save(`contravention_${cvId}.pdf`);
            
            // Optionally save to server
            try {
                const pdfBlob = pdf.output('blob');
                const formData = new FormData();
                formData.append('pdf', pdfBlob, `contravention_${cvId}.pdf`);

                const resp = await fetch(`/api/routes/index.php?route=/contravention/${cvId}/save-pdf`, { 
                    method: 'POST', 
                    body: formData 
                });
                
                if (resp.ok) {
                    console.log('PDF sauvegardé sur le serveur');
                }
            } catch (saveErr) {
                console.warn('Impossible de sauvegarder sur le serveur:', saveErr);
            }
            
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
