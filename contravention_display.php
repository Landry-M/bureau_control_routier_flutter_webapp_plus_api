<?php
// Page de prévisualisation de la contravention - Version corrigée
// Paramètres: ?id={contravention_id}

require_once __DIR__ . '/api/config/database.php';
require_once __DIR__ . '/api/controllers/ContraventionController.php';

if (!isset($_SESSION)) { 
    session_start(); 
}

// Récupérer l'ID de la contravention
$cvId = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($cvId <= 0) {
    echo '<div style="margin:40px;text-align:center;color:red;">ID de contravention manquant</div>';
    exit;
}

// Récupérer les données de la contravention
$contraventionController = new ContraventionController();
$result = $contraventionController->getById($cvId);

if (!$result['success']) {
    echo '<div style="margin:40px;text-align:center;color:red;">Contravention introuvable</div>';
    exit;
}

$cv = $result['data'];

// Initialiser les données du contrevenant et du véhicule
$contrevenant = [
    'nom_prenom' => '',
    'sexe' => '',
    'date_naissance' => '',
    'numero_identite' => '',
    'adresse' => '',
    'telephone' => '',
    'email' => '',
];

$vehicule = [
    'marque' => '',
    'plaque' => '',
    'couleur' => ''
];

$type = trim((string)$cv['type_dossier']);
$dossierId = (int)$cv['dossier_id'];

// Récupérer les informations selon le type de dossier
try {
    $database = new Database();
    $db = $database->getConnection();
    
    if ($type === 'particulier') {
        $stmt = $db->prepare("SELECT * FROM particuliers WHERE id = :id");
        $stmt->bindParam(':id', $dossierId);
        $stmt->execute();
        $p = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($p) {
            $contrevenant['nom_prenom'] = (string)($p['nom'] ?? '');
            $contrevenant['sexe'] = (string)($p['genre'] ?? '');
            $contrevenant['date_naissance'] = (string)($p['date_naissance'] ?? '');
            $contrevenant['numero_identite'] = (string)($p['numero_national'] ?? '');
            $contrevenant['adresse'] = (string)($p['adresse'] ?? '');
            $contrevenant['telephone'] = (string)($p['gsm'] ?? '');
            $contrevenant['email'] = (string)($p['email'] ?? '');
        }
    } elseif ($type === 'entreprise') {
        $stmt = $db->prepare("SELECT * FROM entreprises WHERE id = :id");
        $stmt->bindParam(':id', $dossierId);
        $stmt->execute();
        $e = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($e) {
            $designation = trim((string)($e['designation'] ?? ''));
            $contact = trim((string)($e['personne_contact'] ?? ''));
            $contrevenant['nom_prenom'] = $designation && $contact ? ($designation . ' - ' . $contact) : ($designation ?: $contact);
            
            $siege = trim((string)($e['siege_social'] ?? ''));
            $adresse = trim((string)($e['adresse'] ?? ''));
            $contrevenant['adresse'] = $siege !== '' ? $siege : $adresse;
            
            $gsm = trim((string)($e['gsm'] ?? ''));
            $tel = trim((string)($e['telephone'] ?? ''));
            $contrevenant['telephone'] = $gsm !== '' ? $gsm : $tel;
            $contrevenant['email'] = (string)($e['email'] ?? '');
            $contrevenant['numero_identite'] = (string)($e['rccm'] ?? '');
        }
    } elseif ($type === 'vehicule_plaque') {
        $stmt = $db->prepare("SELECT * FROM vehicule_plaque WHERE id = :id");
        $stmt->bindParam(':id', $dossierId);
        $stmt->execute();
        $v = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($v) {
            $vehicule['marque'] = (string)($v['marque'] ?? '');
            $vehicule['plaque'] = (string)($v['plaque'] ?? '');
            $vehicule['couleur'] = (string)($v['couleur'] ?? '');
        }
    }
} catch (Exception $e) {
    // Silencieux en cas d'erreur
}

// Formater la date
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

$payload = [
    'type_dossier' => (string)($cv['type_dossier'] ?? ''),
    'numero_contravention' => (string)($cv['id'] ?? ''),
    'nom_prenom' => $contrevenant['nom_prenom'],
    'sexe' => strtolower($contrevenant['sexe']),
    'date_naissance' => (string)$contrevenant['date_naissance'],
    'numero_identite' => $contrevenant['numero_identite'],
    'adresse' => $contrevenant['adresse'],
    'telephone' => $contrevenant['telephone'],
    'email' => $contrevenant['email'],
    'marque_vehicule' => $vehicule['marque'],
    'immatriculation' => $vehicule['plaque'],
    'couleur_vehicule' => $vehicule['couleur'],
    'date_infraction' => $cv_date,
    'heure_infraction' => $cv_heure,
    'lieu_infraction' => (string)($cv['lieu'] ?? ''),
    'description_infraction' => (string)($cv['description'] ?? ''),
    'montant_amende' => (string)($cv['amende'] ?? ''),
    'reference_legale' => (string)($cv['reference_loi'] ?? ''),
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
    <title>Contravention #<?php echo htmlspecialchars($cv['id']); ?></title>
    <style>
        body { 
            background: #f5f6f8; 
            margin: 0; 
            padding: 20px; 
            font-family: Arial, sans-serif; 
        }
        .actions { 
            text-align: center; 
            margin: 10px 0 20px; 
        }
        .btn { 
            display: inline-block; 
            padding: 10px 16px; 
            margin: 0 6px; 
            border-radius: 4px; 
            border: none; 
            cursor: pointer; 
            font-weight: bold; 
            text-decoration: none;
        }
        .btn-primary { 
            background: #00509e; 
            color: #fff; 
        }
        .btn-secondary { 
            background: #6c757d; 
            color: #fff; 
        }
        .paper { 
            background: #fff; 
            max-width: 900px; 
            margin: 0 auto; 
            padding: 30px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.08); 
            border-radius: 8px;
        }
        .header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 30px;
            border-bottom: 2px solid #00509e;
            padding-bottom: 20px;
        }
        .header-left {
            flex: 1;
            text-align: left;
        }
        .header-center {
            flex: 2;
            text-align: center;
        }
        .header-right {
            flex: 1;
            text-align: right;
        }
        .header-logo {
            max-height: 80px;
            max-width: 120px;
        }
        .header h1 {
            color: #00509e;
            margin: 0;
            font-size: 25px;
        }
        .header h2 {
            color: #666;
            margin: 5px 0 0 0;
            font-size: 15px;
            font-weight: normal;
        }
        .header .bureau-title {
            color: #333;
            margin: 0 0 10px 0;
            font-size: 27px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .section {
            margin-bottom: 25px;
        }
        .section h3 {
            color: #00509e;
            border-bottom: 1px solid #ddd;
            padding-bottom: 5px;
            margin-bottom: 15px;
        }
        .field-group {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            margin-bottom: 15px;
        }
        .field {
            flex: 1;
            min-width: 200px;
        }
        .field label {
            display: block;
            font-weight: bold;
            color: #333;
            margin-bottom: 5px;
        }
        .field-value {
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            background: #f9f9f9;
            min-height: 20px;
        }
        .coordinates {
            background: #e8f4fd;
            padding: 15px;
            border-radius: 6px;
            margin-top: 15px;
        }
        @media print { 
            .actions { display: none; } 
            body { background: #fff; } 
            .paper { box-shadow: none; } 
        }
    </style>
</head>
<body>

<div class="actions">
    <button onclick="window.print()" class="btn btn-secondary">Imprimer</button>
    <button onclick="downloadPDF()" class="btn btn-primary">Télécharger PDF</button>
</div>

<div id="paper" class="paper">
    <div class="header">
        <div class="header-left">
            <img src="api/assets/images/drapeau.png" alt="Drapeau RDC" class="header-logo">
        </div>
        <div class="header-center">
            <div class="bureau-title">Bureau de Contrôle Routier</div>
            <h1>CONTRAVENTION</h1>
            <h2>N° <?php echo htmlspecialchars($cv['id']); ?></h2>
        </div>
        <div class="header-right">
            <img src="api/assets/images/logo.png" alt="Logo" class="header-logo">
        </div>
    </div>

    <?php if ($type !== 'vehicule_plaque'): ?>
    <div class="section">
        <h3>Informations du contrevenant</h3>
        <div class="field-group">
            <div class="field">
                <label><?php echo $type === 'entreprise' ? 'Nom de l\'entreprise' : 'Nom et prénom'; ?> :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['nom_prenom']); ?></div>
            </div>
            <div class="field">
                <label><?php echo $type === 'entreprise' ? 'RCCM' : 'N° Identité'; ?> :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['numero_identite']); ?></div>
            </div>
        </div>
        <div class="field-group">
            <div class="field">
                <label>Adresse :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['adresse']); ?></div>
            </div>
            <div class="field">
                <label>Téléphone :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['telephone']); ?></div>
            </div>
        </div>
    </div>
    <?php endif; ?>

    <?php if (!empty($payload['marque_vehicule']) || !empty($payload['immatriculation'])): ?>
    <div class="section">
        <h3>Informations du véhicule</h3>
        <div class="field-group">
            <div class="field">
                <label>Marque :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['marque_vehicule']); ?></div>
            </div>
            <div class="field">
                <label>Plaque d'immatriculation :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['immatriculation']); ?></div>
            </div>
            <div class="field">
                <label>Couleur :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['couleur_vehicule']); ?></div>
            </div>
        </div>
    </div>
    <?php endif; ?>

    <div class="section">
        <h3>Détails de l'infraction</h3>
        <div class="field-group">
            <div class="field">
                <label>Date :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['date_infraction']); ?></div>
            </div>
            <div class="field">
                <label>Heure :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['heure_infraction']); ?></div>
            </div>
        </div>
        <div class="field-group">
            <div class="field">
                <label>Lieu de l'infraction :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['lieu_infraction']); ?></div>
            </div>
        </div>
        <div class="field-group">
            <div class="field">
                <label>Type d'infraction :</label>
                <div class="field-value"><?php echo htmlspecialchars($cv['type_infraction'] ?? ''); ?></div>
            </div>
        </div>
        <div class="field-group">
            <div class="field">
                <label>Description :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['description_infraction']); ?></div>
            </div>
        </div>
        <div class="field-group">
            <div class="field">
                <label>Référence légale :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['reference_legale']); ?></div>
            </div>
            <div class="field">
                <label>Montant de l'amende :</label>
                <div class="field-value"><?php echo htmlspecialchars($payload['montant_amende']); ?> FC</div>
            </div>
        </div>

        <?php if (!empty($payload['latitude']) && !empty($payload['longitude'])): ?>
        <div class="coordinates">
            <strong>📍 Coordonnées géographiques :</strong><br>
            Latitude: <?php echo htmlspecialchars($payload['latitude']); ?><br>
            Longitude: <?php echo htmlspecialchars($payload['longitude']); ?>
        </div>
        <?php endif; ?>
    </div>

    <div class="section">
        <h3>Statut</h3>
        <div class="field-group">
            <div class="field">
                <label>Amende payée :</label>
                <div class="field-value">
                    <?php echo ($cv['payed'] === 'oui' || $cv['payed'] === '1') ? '✅ Oui' : '❌ Non'; ?>
                </div>
            </div>
        </div>
    </div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
<script>
async function downloadPDF() {
    try {
        const element = document.getElementById('paper');
        
        // Masquer les actions pendant la capture
        const actions = document.querySelector('.actions');
        if (actions) actions.style.display = 'none';
        
        // Capturer l'élément en canvas
        const canvas = await html2canvas(element, {
            scale: 2,
            useCORS: true,
            allowTaint: true,
            backgroundColor: '#ffffff',
            width: element.scrollWidth,
            height: element.scrollHeight
        });
        
        // Restaurer les actions
        if (actions) actions.style.display = 'block';
        
        // Créer le PDF
        const { jsPDF } = window.jspdf;
        const pdf = new jsPDF({
            orientation: 'portrait',
            unit: 'mm',
            format: 'a4'
        });
        
        const imgData = canvas.toDataURL('image/png');
        const pageWidth = pdf.internal.pageSize.getWidth();
        const pageHeight = pdf.internal.pageSize.getHeight();
        
        // Calculer les dimensions pour ajuster à la page
        const imgWidth = pageWidth - 20; // marges de 10mm de chaque côté
        const imgHeight = (canvas.height * imgWidth) / canvas.width;
        
        let y = 10; // marge du haut
        
        // Si l'image est plus haute que la page, la diviser
        if (imgHeight > pageHeight - 20) {
            const ratio = (pageHeight - 20) / imgHeight;
            const adjustedWidth = imgWidth * ratio;
            const adjustedHeight = imgHeight * ratio;
            const x = (pageWidth - adjustedWidth) / 2;
            
            pdf.addImage(imgData, 'PNG', x, y, adjustedWidth, adjustedHeight);
        } else {
            const x = (pageWidth - imgWidth) / 2;
            pdf.addImage(imgData, 'PNG', x, y, imgWidth, imgHeight);
        }
        
        // Télécharger le PDF
        const contraventionId = <?php echo json_encode($cvId); ?>;
        pdf.save(`contravention_${contraventionId}.pdf`);
        
        // Optionnel : sauvegarder aussi sur le serveur
        try {
            const pdfBlob = pdf.output('blob');
            const formData = new FormData();
            formData.append('pdf', pdfBlob, `contravention_${contraventionId}.pdf`);
            formData.append('contravention_id', contraventionId);
            
            const response = await fetch('api/routes/index.php?route=/contravention/' + contraventionId + '/save-pdf', {
                method: 'POST',
                body: formData
            });
            
            if (response.ok) {
                console.log('PDF sauvegardé sur le serveur');
            }
        } catch (serverError) {
            console.warn('Erreur lors de la sauvegarde serveur:', serverError);
            // Continue même si la sauvegarde serveur échoue
        }
        
    } catch (error) {
        console.error('Erreur lors de la génération du PDF:', error);
        alert('Erreur lors de la génération du PDF: ' + error.message);
    }
}
</script>

</body>
</html>
