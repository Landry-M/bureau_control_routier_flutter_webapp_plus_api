<?php
// Page d'affichage de la plaque temporaire
// Paramètres attendus : ?id={permis_id} ou ?vehicule_id={id}&numero={numero}

require_once __DIR__ . '/config/database.php';

// Pas besoin d'ORM, on utilise PDO directement

if(!isset($_SESSION))
{
   session_start();
}

// Initialiser la connexion
$database = new Database();
$pdo = $database->getConnection();

// Récupérer les paramètres
$permisId = (int)($_GET['id'] ?? 0);
$vehiculeId = (int)($_GET['vehicule_id'] ?? 0);
$numero = trim((string)($_GET['numero'] ?? ''));

$permis = null;
$vehicule = null;
$error = null;

try {
    if ($permisId > 0) {
        // Récupérer par ID de permis
        $stmt = $pdo->prepare("SELECT * FROM permis_temporaire WHERE id = :id");
        $stmt->bindParam(':id', $permisId, PDO::PARAM_INT);
        $stmt->execute();
        $permis = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($permis && $permis['cible_type'] === 'vehicule_plaque') {
            $vehiculeId = (int)$permis['cible_id'];
        }
    } elseif ($vehiculeId > 0 && $numero !== '') {
        // Récupérer par vehicule_id et numéro
        $stmt = $pdo->prepare("SELECT * FROM permis_temporaire WHERE cible_type = 'vehicule_plaque' AND cible_id = :cible_id AND numero = :numero");
        $stmt->bindParam(':cible_id', $vehiculeId, PDO::PARAM_INT);
        $stmt->bindParam(':numero', $numero);
        $stmt->execute();
        $permis = $stmt->fetch(PDO::FETCH_ASSOC);
    }

    if (!$permis) {
        $error = "Plaque temporaire introuvable";
    } else {
        // Récupérer les infos du véhicule
        $stmt = $pdo->prepare("SELECT * FROM vehicule_plaque WHERE id = :id");
        $stmt->bindParam(':id', $vehiculeId, PDO::PARAM_INT);
        $stmt->execute();
        $vehicule = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$vehicule) {
            $error = "Véhicule introuvable";
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

// Formater les données du véhicule
$marque = htmlspecialchars((string)($vehicule['marque'] ?? ''), ENT_QUOTES);
$modele = htmlspecialchars((string)($vehicule['modele'] ?? ''), ENT_QUOTES);
$couleur = htmlspecialchars((string)($vehicule['couleur'] ?? ''), ENT_QUOTES);
$annee_fab = htmlspecialchars((string)($vehicule['annee_fab'] ?? ''), ENT_QUOTES);
$plaque = htmlspecialchars((string)($vehicule['plaque'] ?? ''), ENT_QUOTES);
$numero_chassis = htmlspecialchars((string)($vehicule['numero_chassis'] ?? ''), ENT_QUOTES);
$numero_moteur = htmlspecialchars((string)($vehicule['numero_moteur'] ?? ''), ENT_QUOTES);

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

// Fonction pour formater les dates au format Année-Mois-Jour
$fmtYMD = function($d) { 
    if(!$d) return ''; 
    try { 
        $t = strtotime($d); 
        return $t ? date('Y-m-d', $t) : $d; 
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
    <title>Plaque d'immatriculation provisoire</title>
    <style>
        body {
            background-color: #f0f0f0;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            font-family: Arial, sans-serif;
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

        .info-section {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            max-width: 800px;
            width: 100%;
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

        .container {
            width: 800px;
            padding: 20px;
            background-color: #fff;
            border: 1px solid #000;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            position: relative;
            margin-bottom: 30px;
        }

        .header-top {
            display: flex;
            justify-content: space-between;
            position: absolute;
            top: 10px;
            left: 50%;
            transform: translateX(-50%);
            width: 95%;
        }

        .header-top .hole {
            width: 20px;
            height: 20px;
            border: 1px solid #000;
            border-radius: 50%;
        }

        .content {
            border: 1px solid #000;
            padding: 10px;
            margin-top: 30px;
        }
        
        .header-section {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding-bottom: 10px;
            border-bottom: 2px solid #000;
        }

        .logo-and-motto {
            display: flex;
            align-items: center;
        }

        .logo {
            font-weight: bold;
            font-size: 14px;
            line-height: 1.2;
            margin-right: 10px;
        }

        .logo-text {
            display: flex;
            flex-direction: column;
            font-size: 10px;
        }

        .logo-text .slogan {
            font-style: italic;
        }

        .quebec-logo {
            display: flex;
            align-items: center;
            margin-left: 10px;
        }

        .quebec-logo .plus {
            font-size: 20px;
            font-weight: bold;
            color: #0080ff;
        }

        .quebec-logo .cross {
            width: 15px;
            height: 15px;
            background-color: #0080ff;
            margin: 0 2px;
        }

        .title {
            font-size: 20px;
            font-weight: bold;
        }

        .validity-section {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-top: 10px;
        }

        .important-note {
            width: 60%;
            font-size: 10px;
            line-height: 1.4;
        }

        .dates {
            width: 35%;
            display: flex;
            justify-content: space-between;
            font-size: 12px;
            text-align: center;
        }
        
        .date-box {
            border: 1px solid #000;
            padding: 5px;
            flex-grow: 1;
            margin-left: 5px;
        }

        .date-label {
            font-weight: bold;
        }

        .date-value {
            font-size: 14px;
            margin-top: 5px;
        }

        .license-plate {
            text-align: center;
            padding: 40px 0;
            font-size: 80px;
            font-weight: bold;
            letter-spacing: 5px;
            border-bottom: 1px solid #000;
            margin-top: 20px;
            color: #444;
        }

        .footer {
            margin-top: 20px;
            text-align: center;
        }
        
        .contact-note {
            font-size: 10px;
            line-height: 1.5;
            margin-bottom: 10px;
        }

        .contact-info {
            font-size: 10px;
            margin-bottom: 10px;
        }

        .contact-info span {
            margin: 0 5px;
        }

        .slogan-footer {
            font-size: 10px;
            text-align: left;
        }

        .form-id {
            font-size: 8px;
            text-align: left;
            margin-top: 5px;
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

        @media print {
            body {
                background-color: white;
                padding: 0;
            }
            .page-header, .actions, .info-section {
                display: none;
            }
            .container {
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
        <h1>Plaque d'immatriculation provisoire</h1>
        <p>Bureau de Control Routier</p>
        <p><strong>Numéro:</strong> <?= $numero ?> | <strong>Valide du:</strong> <?= $fmt($date_debut) ?> <strong>au:</strong> <?= $fmt($date_fin) ?></p>
    </div>
<!-- 
    <div class="info-section">
        <h3>Informations du Véhicule</h3>
        <div class="info-grid">
            <div class="info-item">
                <span class="info-label">Marque</span>
                <span class="info-value"><?= $marque ?></span>
            </div>
            <div class="info-item">
                <span class="info-label">Modèle</span>
                <span class="info-value"><?= $modele ?></span>
            </div>
            <div class="info-item">
                <span class="info-label">Couleur</span>
                <span class="info-value"><?= $couleur ?></span>
            </div>
            <div class="info-item">
                <span class="info-label">Année de fabrication</span>
                <span class="info-value"><?= $annee_fab ?></span>
            </div>
            <div class="info-item">
                <span class="info-label">Plaque permanente</span>
                <span class="info-value"><?= $plaque ?></span>
            </div>
            <div class="info-item">
                <span class="info-label">Statut</span>
                <span class="info-value"><?= ucfirst($permis['statut'] ?? '') ?></span>
            </div>
        </div>
        <div style="margin-top: 15px;">
            <div class="info-grid">
                <div class="info-item">
                    <span class="info-label">Numéro de châssis</span>
                    <span class="info-value"><?= $numero_chassis ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Numéro de moteur</span>
                    <span class="info-value"><?= $numero_moteur ?></span>
                </div>
            </div>
        </div>
    </div> -->

    <div id="plaque-card-to-export" class="container">
        <div class="header-top">
            <div class="hole"></div>
            <div class="hole"></div>
        </div>

        <div class="content">
            <div class="header-section">
                <div class="logo-and-motto">
                    <div class="logo">
                        Bureau de Control Routier
                    </div>
                    <!-- <div class="quebec-logo">
                        <span class="plus">+</span>
                        <div class="cross"></div>
                        <span class="plus">+</span>
                        <div class="cross"></div>
                        <span class="plus">+</span>
                    </div> -->
                    <!-- <div class="logo-text">
                        <span>Québec</span>
                        <span class="slogan">Au cœur de votre sécurité</span>
                    </div> -->
                </div>
                <div class="title">
                    Plaque d'immatriculation provisoire
                </div>
            </div>
            <div class="validity-section">
                <div class="important-note">
                    <strong>IMPORTANT :</strong> Pour pouvoir circuler, vous devez apposer ce document dans la partie supérieure gauche <br> de la lunette arrière de votre véhicule jusqu'à la réception de votre plaque d'immatriculation.
                </div>
                <div class="dates">
                    <div class="date-box">
                        <div class="date-label">Valide du</div>
                        <div class="date-value">
                            <?= $fmtYMD($date_debut) ?: 'Année-Mois-Jour' ?>
                        </div>
                    </div>
                    <div class="date-box">
                        <div class="date-label">Expire le</div>
                        <div class="date-value">
                            <?= $fmtYMD($date_fin) ?: 'Année-Mois-Jour' ?>
                        </div>
                    </div>
                </div>
            </div>
            <div class="license-plate">
                <?= $numero ?: '12ZZAA' ?>
            </div>
            <div class="footer">
                <div class="contact-note">
                    Si vous n'avez pas reçu votre plaque d'immatriculation d'ici le <?= $fmtYMD($date_fin) ?>, vous pouvez repasser a nos bureau pour le renouvellement.
                </div>
                <div class="contact-info">
                    <strong>République Démocratique du Congo 
                </div>
                <!-- <div class="slogan-footer">
                    Société de l'assurance automobile du Québec
                </div>
                <div class="form-id">
                    E298 00 (2020-05)
                </div> -->
            </div>
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
                alert('ID de la plaque temporaire manquant');
                return;
            }
            
            try {
                // Générer le PDF côté client avec html2canvas + jsPDF
                const element = document.getElementById('plaque-card-to-export');
                
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
                    format: 'a4'
                });
                
                const imgData = canvas.toDataURL('image/png');
                const imgWidth = 297; // A4 landscape width in mm
                const imgHeight = (canvas.height * imgWidth) / canvas.width;
                
                pdf.addImage(imgData, 'PNG', 0, 0, imgWidth, imgHeight);
                
                // Convertir en blob pour l'envoi au serveur
                const pdfBlob = pdf.output('blob');
                
                // Envoyer le PDF au serveur pour sauvegarde
                const formData = new FormData();
                formData.append('pdf', pdfBlob, `plaque_temporaire_${numero}.pdf`);
                formData.append('permis_id', permisId);
                
                const response = await fetch(`http://localhost:8000/api/routes/index.php/plaque-temporaire/${permisId}/save-pdf`, {
                    method: 'POST',
                    body: formData
                });
                
                const result = await response.json();
                
                if (result.ok) {
                    // Télécharger le PDF
                    const downloadLink = document.createElement('a');
                    downloadLink.href = URL.createObjectURL(pdfBlob);
                    downloadLink.download = `plaque_temporaire_${numero}.pdf`;
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
