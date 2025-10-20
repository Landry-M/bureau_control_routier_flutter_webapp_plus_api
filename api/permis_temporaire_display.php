<?php
// Page d'affichage du permis temporaire
// Paramètres acceptés :
//   - ?id={permis_id}
//   - ?particulier_id={id}&numero={numero}
//   - ?particulier_id={id}  (résout automatiquement le permis actif)

require_once __DIR__ . '/config/database.php';

if(!isset($_SESSION)) {
   session_start();
}

// Initialiser la connexion PDO
$database = new Database();
$pdo = $database->getConnection();

if (!$pdo) {
    echo "<div style='text-align: center; margin: 50px; color: red; font-size: 18px;'>Erreur de connexion à la base de données</div>";
    exit;
}

// Récupérer les paramètres
$permisId = (int)($_GET['id'] ?? 0);
$particulierId = (int)($_GET['particulier_id'] ?? 0);
$numero = trim((string)($_GET['numero'] ?? ''));

$permis = null;
$particulier = null;
$error = null;

try {
    if ($permisId > 0) {
        // Récupérer par ID de permis
        $stmt = $pdo->prepare("SELECT * FROM permis_temporaire WHERE id = :id");
        $stmt->bindParam(':id', $permisId);
        $stmt->execute();
        $permis = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($permis) {
            $particulierId = (int)$permis['cible_id'];
        }
    } elseif ($particulierId > 0 && $numero !== '') {
        // Récupérer par particulier_id et numéro
        $stmt = $pdo->prepare("SELECT * FROM permis_temporaire 
                              WHERE cible_type = 'particulier' 
                              AND cible_id = :cible_id 
                              AND numero = :numero");
        $stmt->bindParam(':cible_id', $particulierId);
        $stmt->bindParam(':numero', $numero);
        $stmt->execute();
        $permis = $stmt->fetch(PDO::FETCH_ASSOC);
    } elseif ($particulierId > 0) {
        // Sans numéro fourni: tenter de récupérer le permis actif, sinon le plus récent
        $stmt = $pdo->prepare("SELECT * FROM permis_temporaire 
                              WHERE cible_type = 'particulier' 
                              AND cible_id = :cible_id 
                              ORDER BY id DESC LIMIT 1");
        $stmt->bindParam(':cible_id', $particulierId);
        $stmt->execute();
        $permis = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($permis) {
            // Si plusieurs existent, préférer actif
            $stmt = $pdo->prepare("SELECT * FROM permis_temporaire 
                                  WHERE cible_type = 'particulier' 
                                  AND cible_id = :cible_id 
                                  AND statut = 'actif' 
                                  ORDER BY id DESC LIMIT 1");
            $stmt->bindParam(':cible_id', $particulierId);
            $stmt->execute();
            $active = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($active) { 
                $permis = $active; 
            }
        }
    }

    if (!$permis) {
        $error = "Permis temporaire introuvable";
    } else {
        // Récupérer les infos du particulier
        $stmt = $pdo->prepare("SELECT * FROM particuliers WHERE id = :id");
        $stmt->bindParam(':id', $particulierId);
        $stmt->execute();
        $particulier = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$particulier) {
            $error = "Particulier introuvable";
        }
    }
} catch (Exception $e) {
    $error = "Erreur : " . $e->getMessage();
}

if ($error) {
    echo "<div style='text-align: center; margin: 50px; color: red; font-size: 18px;'>$error</div>";
    exit;
}

// Préparer les données pour l'affichage
$numero = $permis['numero'] ?? '';
$date_debut = $permis['date_debut'] ?? '';
$date_fin = $permis['date_fin'] ?? '';
$motif = htmlspecialchars((string)($permis['motif'] ?? ''), ENT_QUOTES);

// Formater les données du particulier
$nom = htmlspecialchars((string)($particulier['nom'] ?? ''), ENT_QUOTES);
$prenom = '';
// Séparer nom et prénom si stockés ensemble
if ($nom && strpos($nom, ' ') !== false) {
    $pieces = preg_split('/\s+/', $nom, 2);
    if (is_array($pieces)) { 
        $nom = htmlspecialchars($pieces[0] ?? '', ENT_QUOTES); 
        $prenom = htmlspecialchars($pieces[1] ?? '', ENT_QUOTES); 
    }
}

$numero_national = htmlspecialchars((string)($particulier['numero_national'] ?? ''), ENT_QUOTES);
$adresse = htmlspecialchars((string)($particulier['adresse'] ?? ''), ENT_QUOTES);
$nationalite = htmlspecialchars((string)($particulier['nationalite'] ?? 'Congolaise'), ENT_QUOTES);
$date_naissance = htmlspecialchars((string)($particulier['date_naissance'] ?? ''), ENT_QUOTES);
$lieu_naissance = htmlspecialchars((string)($particulier['lieu_naissance'] ?? ''), ENT_QUOTES);

// Déterminer l'URL de base pour les assets
$protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
$baseUrl = $protocol . '://' . $host;

// Gérer la photo
$photoSrc = '';
$photoRel = (string)($particulier['photo'] ?? '');
if ($photoRel !== '') {
    // Essayer plusieurs chemins possibles
    $possiblePaths = [
        __DIR__ . '/../' . ltrim($photoRel, '/'),
        __DIR__ . '/' . ltrim($photoRel, '/'),
        __DIR__ . '/../uploads/' . ltrim($photoRel, '/'),
    ];
    
    foreach ($possiblePaths as $fsPath) {
        if (is_file($fsPath)) {
            $mime = 'image/jpeg';
            $ext = strtolower(pathinfo($fsPath, PATHINFO_EXTENSION));
            if ($ext === 'png') $mime = 'image/png'; 
            elseif ($ext === 'gif') $mime = 'image/gif';
            $photoData = @file_get_contents($fsPath);
            if ($photoData !== false) { 
                $photoSrc = 'data:' . $mime . ';base64,' . base64_encode($photoData); 
                break;
            }
        }
    }
}

// Fonction pour formater les dates
$fmt = function($d) { 
    if(!$d) return ''; 
    try { 
        $t = strtotime($d); 
        return $t ? date('d/m/Y', $t) : $d; 
    } catch(Throwable $e) { 
        return $d; 
    } 
};
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Permis de Conduire Temporaire - RDC</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Roboto+Condensed:wght@400;700&display=swap');

        body {
            background-color: #f0f0f0;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            font-family: 'Roboto Condensed', sans-serif;
            padding: 20px;
        }

        .page-header {
            text-align: center;
            margin-bottom: 30px;
            color: #00509e;
        }

        .page-header h1 {
            font-size: 28px;
            margin: 0 0 10px 0;
            font-weight: 700;
        }

        .page-header p {
            font-size: 16px;
            margin: 5px 0;
            color: #666;
        }

        .licence-card {
            width: 500px;
            height: 315px;
            background-color: #ffffff;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
            position: relative;
            overflow: hidden;
            border: 2px solid #00509e;
            box-sizing: border-box;
            margin-bottom: 30px;
        }

        .background-text {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            overflow: hidden;
            opacity: 0.1;
            transform: rotate(-10deg);
            z-index: 1;
        }

        .background-text p {
            font-size: 14px;
            font-weight: bold;
            color: #00509e;
            white-space: nowrap;
            letter-spacing: 1px;
            line-height: 1.2;
            text-transform: uppercase;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            position: relative;
            z-index: 2;
        }

        .header .flag-and-title {
            display: flex;
            align-items: center;
        }

        .header .flag {
            width: 40px;
            height: 27px;
            margin-right: 10px;
            object-fit: contain;
        }

        .header .title {
            text-align: center;
        }

        .header h1 {
            font-size: 18px;
            font-weight: 700;
            color: #00509e;
            margin: 0;
            text-transform: uppercase;
        }

        .header .subtitle {
            font-size: 12px;
            font-weight: 700;
            color: #000;
            margin: 3px 0 0;
        }
        
        .header .cgo {
            font-size: 16px;
            font-weight: bold;
            color: #fff;
            background-color: #00509e;
            padding: 3px 10px;
            border-radius: 12px;
            border: 2px solid #000;
        }

        .content {
            display: flex;
            position: relative;
            z-index: 2;
            height: calc(100% - 70px);
        }

        .left-section {
            width: 30%;
            padding-right: 15px;
            display: flex;
            flex-direction: column;
        }

        .photo-container {
            width: 100%;
            height: 125px;
            background-color: #ccc;
            border: 1px solid #000;
            margin-bottom: 10px;
            display: flex;
            justify-content: center;
            align-items: center;
            font-size: 10px;
            color: #666;
            text-align: center;
            overflow: hidden;
        }

        .photo-container img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .categories {
            background-color: #00509e;
            color: #fff;
            padding: 3px;
            border-radius: 3px;
            text-align: center;
            margin-bottom: 10px;
            border: 1px solid #000;
        }

        .categories .label {
            font-size: 10px;
            font-weight: bold;
            display: block;
        }

        .categories .list {
            display: flex;
            justify-content: center;
            align-items: center;
            margin-top: 3px;
        }

        .categories .list span {
            font-size: 18px;
            font-weight: bold;
            padding: 0 5px;
            border: 1px solid #fff;
            margin: 0 1px;
        }

        .categories .list span.active {
            background-color: #fff;
            color: #00509e;
        }
        
        .categories .list .asterisk {
            font-size: 18px;
            font-weight: bold;
        }

        .signature {
            border-top: 1px solid #000;
            padding-top: 3px;
        }
        
        .signature .label {
            font-size: 9px;
            font-weight: bold;
        }

        .right-section {
            width: 70%;
            display: grid;
            grid-template-columns: 1fr 1fr;
            grid-template-rows: repeat(8, auto) 1fr;
            gap: 3px 10px;
        }

        .right-section .field {
            display: flex;
            flex-direction: column;
            font-size: 10px;
        }

        .right-section .field-wide {
            grid-column: span 2;
        }

        .right-section .field-wide.address {
            height: 40px;
        }
        
        .right-section .field .label {
            font-size: 9px;
            font-weight: bold;
            color: #00509e;
            text-transform: uppercase;
        }
        
        .right-section .field .value {
            font-size: 12px;
            font-weight: bold;
            border-bottom: 1px solid #000;
            padding-bottom: 1px;
            color: #000;
        }

        .coat-of-arms {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 200px;
            height: 200px;
            opacity: 0.15;
            pointer-events: none;
            z-index: 0;
            background-size: contain;
            background-repeat: no-repeat;
            background-position: center;
            background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500"><g opacity="1"><path d="M250,50c-110.5,0-200,89.5-200,200s89.5,200,200,200,200-89.5,200-200-89.5-200-200-200z" fill="#00509e"/><path d="M250,60c104.9,0,190,85.1,190,190S354.9,440,250,440,60,354.9,60,250,145.1,60,250,60z" fill="#fff"/><g><path d="M250,120c-71.8,0-130,58.2-130,130s58.2,130,130,130,130-58.2,130-130-58.2-130-130-130z" fill="#00509e"/><path d="M250,130c66.3,0,120,53.7,120,120s-53.7,120-120,120-120-53.7-120-120,53.7-120,120-120z" fill="#fff"/></g></g><g opacity="1"><path d="M250,160c-49.7,0-90,40.3-90,90s40.3,90,90,90,90-40.3,90-90-40.3-90-90-90z" fill="#00509e"/><path d="M250,170c44.2,0,80,35.8,80,80s-35.8,80-80,80-80-35.8-80-80,35.8-80,80-80z" fill="#fff"/></g><path d="M250,190c-33.1,0-60,26.9-60,60s26.9,60,60,60,60-26.9,60-60-26.9-60-60-60z" fill="#00509e"/></svg>');
        }

        .barcode-container {
            position: absolute;
            bottom: 15px;
            left: 50%;
            transform: translateX(-50%);
            width: 90%;
            height: 30px;
            background-color: #000;
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 2;
        }
        
        .barcode-container .barcode {
            width: 95%;
            height: 20px;
            background-color: #fff;
            position: relative;
        }

        .actions {
            text-align: center;
            margin-top: 20px;
        }

        .btn {
            display: inline-block;
            padding: 12px 24px;
            margin: 0 10px;
            font-size: 16px;
            font-weight: bold;
            text-decoration: none;
            border-radius: 5px;
            cursor: pointer;
            border: none;
            transition: background-color 0.3s;
        }

        .btn-primary {
            background-color: #00509e;
            color: white;
        }

        .btn-primary:hover {
            background-color: #003d7a;
        }

        .btn-secondary {
            background-color: #6c757d;
            color: white;
        }

        .btn-secondary:hover {
            background-color: #545b62;
        }

        .info-section {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            max-width: 500px;
        }

        .info-section h3 {
            color: #00509e;
            margin-top: 0;
            border-bottom: 2px solid #00509e;
            padding-bottom: 10px;
        }

        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-top: 15px;
        }

        .info-item {
            display: flex;
            flex-direction: column;
        }

        .info-label {
            font-weight: bold;
            color: #666;
            font-size: 14px;
            margin-bottom: 5px;
        }

        .info-value {
            font-size: 16px;
            color: #333;
        }

        @media print {
            body {
                background-color: white;
                padding: 0;
            }
            .page-header, .actions, .info-section {
                display: none;
            }
            .licence-card {
                box-shadow: none;
                margin: 0;
            }
        }
    </style>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
</head>
<body>
    <div class="page-header">
        <h1>Permis de Conduire Temporaire</h1>
        <p>République Démocratique du Congo</p>
        <p><strong>Numéro:</strong> <?= $numero ?> | <strong>Valide du:</strong> <?= $fmt($date_debut) ?> <strong>au:</strong> <?= $fmt($date_fin) ?></p>
    </div>

    <div id="licence-card-to-export" class="licence-card">
        <div class="background-text">
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
            <p>REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO REPUBLIQUE DEMOCRATIQUE DU CONGO</p>
        </div>

        <div class="header">
            <div class="flag-and-title">
                <img src="<?= $baseUrl ?>/api/assets/images/drapeau.png" 
                     alt="Drapeau RDC" 
                     class="flag"
                     onerror="this.style.display='none'">
                <div class="title">
                    <h1>REPUBLIQUE DEMOCRATIQUE DU CONGO</h1>
                    <div class="subtitle">PERMIS DE CONDUIRE * TEMPORAIRE</div>
                </div>
            </div>
            <div class="cgo">CGO</div>
        </div>

        <div class="content">
            <div class="left-section">
                <div class="photo-container">
                    <?php if (!empty($photoSrc)): ?>
                        <img src="<?= $photoSrc ?>" alt="Photo">
                    <?php else: ?>
                        <span>PHOTO</span>
                    <?php endif; ?>
                </div>
                <div class="categories">
                    <div class="label">9. CATEGORIES</div>
                    <div class="list">
                        <span class="active">A</span>
                        <span class="active">B</span>
                        <span class="active">C</span>
                        <span class="active">D</span>
                        <span class="asterisk">*</span>
                    </div>
                </div>
                <div class="signature">
                    <div class="label">42. SIGNATURE DU PORTEUR</div>
                </div>
            </div>

            <div class="right-section">
                <div class="field field-wide">
                    <span class="label">1. NOM</span>
                    <span class="value"><?= $nom ?></span>
                </div>
                <div class="field field-wide">
                    <span class="label">2. PRENOM</span>
                    <span class="value"><?= $prenom ?></span>
                </div>
                <div class="field">
                    <span class="label">3. DATE ET LIEU NAISSANCE</span>
                    <span class="value"><?= $fmt($date_naissance) ?><?= $lieu_naissance ? ' ' . $lieu_naissance : '' ?></span>
                </div>
                <div class="field">
                    <span class="label">32. NATIONALITE</span>
                    <span class="value"><?= $nationalite ?></span>
                </div>
                <div class="field">
                    <span class="label">33. N° P.N.</span>
                    <span class="value"><?= $numero_national ?></span>
                </div>
                <div class="field">
                    <span class="label">34. N° PERMIS TEMPORAIRE</span>
                    <span class="value"><?= $numero ?></span>
                </div>
                <div class="field field-wide address">
                    <span class="label">31. ADRESSE</span>
                    <span class="value"><?= $adresse ?></span>
                </div>
                <div class="field field-wide">
                    <span class="label">12. REMARQUES ET RESTRICTIONS</span>
                    <span class="value"><?= $motif ?: 'PERMIS TEMPORAIRE' ?></span>
                </div>
                <div class="field">
                    <span class="label">4A. DATE DE DELIVRANCE</span>
                    <span class="value"><?= $fmt($date_debut) ?></span>
                </div>
                <div class="field">
                    <span class="label">4B. DATE D'ECHEANCE</span>
                    <span class="value"><?= $fmt($date_fin) ?></span>
                </div>
            </div>
        </div>

        <div class="coat-of-arms"></div>

        <div class="barcode-container">
            <div class="barcode"></div>
        </div>
    </div>

    <div class="actions">
        <button id="export-pdf-btn" class="btn btn-primary">Télécharger et Enregistrer en PDF</button>
        <!-- <button onclick="window.print()" class="btn btn-secondary">Imprimer</button> -->
        <!-- <a href="javascript:history.back()" class="btn btn-secondary">Retour</a> -->
    </div>

    <script>
        document.getElementById('export-pdf-btn').addEventListener('click', async function() {
            const permisId = <?= json_encode($permisId ?? '') ?>;
            const numero = <?= json_encode($numero ?? '') ?>;
            
            if (!permisId) {
                alert('ID du permis temporaire manquant');
                return;
            }
            
            try {
                // Générer le PDF côté client avec html2canvas + jsPDF
                const element = document.getElementById('licence-card-to-export');
                
                // Configuration html2canvas
                const canvas = await html2canvas(element, {
                    scale: 2,
                    useCORS: true,
                    allowTaint: true,
                    backgroundColor: '#ffffff'
                });
                
                // Créer le PDF avec jsPDF
                const { jsPDF } = window.jspdf;
                const pdf = new jsPDF({
                    orientation: 'landscape',
                    unit: 'mm',
                    format: [85.6, 54] // Format carte de crédit
                });
                
                const imgData = canvas.toDataURL('image/png');
                pdf.addImage(imgData, 'PNG', 0, 0, 85.6, 54);
                
                // Convertir en blob pour l'envoi au serveur
                const pdfBlob = pdf.output('blob');
                
                // Envoyer le PDF au serveur pour sauvegarde
                const formData = new FormData();
                formData.append('pdf', pdfBlob, `permis_temporaire_${numero}.pdf`);
                formData.append('permis_id', permisId);
                
                // Construire l'URL relative depuis le répertoire api
                const apiUrl = window.location.origin + '/api/routes/index.php/permis-temporaire/' + permisId + '/save-pdf';
                
                const response = await fetch(apiUrl, {
                    method: 'POST',
                    body: formData
                });
                
                const result = await response.json();
                
                if (result.ok) {
                    // Télécharger le PDF
                    const downloadLink = document.createElement('a');
                    downloadLink.href = URL.createObjectURL(pdfBlob);
                    downloadLink.download = `permis_temporaire_${numero}.pdf`;
                    downloadLink.target = '_blank';
                    document.body.appendChild(downloadLink);
                    downloadLink.click();
                    document.body.removeChild(downloadLink);
                    
                    alert('PDF sauvegardé et téléchargé avec succès');
                } else {
                    throw new Error(result.error || 'Erreur lors de la sauvegarde');
                }
            } catch (error) {
                console.error('Erreur:', error);
                alert('Erreur lors de la sauvegarde du PDF: ' + error.message);
            }
        });
    </script>
</body>
</html>
