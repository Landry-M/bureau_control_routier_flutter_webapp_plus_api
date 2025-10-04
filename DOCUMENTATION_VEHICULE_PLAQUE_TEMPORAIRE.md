
### Structure des données

#### Table `vehicule_plaque`
```sql
CREATE TABLE vehicule_plaque (
    id INT PRIMARY KEY AUTO_INCREMENT,
    images TEXT, -- JSON array des chemins d'images
    marque VARCHAR(100) NOT NULL,
    modele VARCHAR(100),
    annee VARCHAR(4),
    couleur VARCHAR(50) NOT NULL,
    numero_chassis VARCHAR(100),
    frontiere_entree VARCHAR(100),
    date_importation DATE,
    plaque VARCHAR(20),
    plaque_valide_le DATE,
    plaque_expire_le DATE,
    nume_assurance VARCHAR(100),
    societe_assurance VARCHAR(100),
    date_valide_assurance DATE,
    date_expire_assurance DATE,
    -- Détails techniques DGI
    genre VARCHAR(50),
    usage VARCHAR(50),
    numero_declaration VARCHAR(100), -- Numéro volet jaune
    num_moteur VARCHAR(100),
    origine VARCHAR(100),
    source VARCHAR(100),
    annee_fab VARCHAR(4),
    annee_circ VARCHAR(4),
    type_em VARCHAR(50),
    en_circulation TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```
   }
}
```

### Gestion du switch contravention
```javascript
// Switch pour attribution directe de contravention
const assignSwitch = document.getElementById('assign_contravention_switch_vehicule');
const contraventionSection = document.getElementById('contravention-section-vehicule');
const btnText = document.getElementById('btn-text-vehicule');

assignSwitch.addEventListener('change', function() {
    if (this.checked) {
        contraventionSection.classList.remove('d-none');
        btnText.textContent = 'Enregistrer le véhicule et créer la contravention';
    } else {
        contraventionSection.classList.add('d-none');
        btnText.textContent = 'Enregistrer le véhicule';
    }
});
```

## Backend - Contrôleur PHP

### VehiculePlaqueController

#### Méthode create()
```php
public function create($data)
{
    $this->getConnexion();
    
    // 1. Vérification unicité plaque
    if (isset($data['plaque']) && !empty(trim($data['plaque']))) {
        $existingVehicle = $this->checkPlaqueExists(trim($data['plaque']));
        if ($existingVehicle) {
            throw new Exception('Cette plaque d\'immatriculation existe déjà dans le système (ID: ' . $existingVehicle['id'] . ')');
        }
    }
    
    // 2. Gestion upload images multiples
    $imagePaths = [];
    if (isset($_FILES['images'])) {
        $imagePaths = $this->handleImageUploads($_FILES['images']);
    }
    
    // 3. Création enregistrement véhicule
    $vehicule_plaque = ORM::for_table('vehicule_plaque')->create();
    $vehicule_plaque->images = json_encode($imagePaths);
    // ... assignation des champs
    $vehicule_plaque->save();
    
    // 4. Création enregistrement assurance
    $this->createAssuranceRecord($vehiculeId, $data);
    
    // 5. Logging activité
    $this->activityLogger->logCreate(/* ... */);
    
    return $vehiculeId;
}
```

#### Méthode createWithContravention()
```php
public function createWithContravention($data)
{
    $result = ['state' => false, 'message' => ''];
    
    try {
        // Transaction pour cohérence des données
        ORM::get_db()->beginTransaction();
        
        // 1. Créer le véhicule
        $vehiculeId = $this->create($data);
        
        // 2. Créer la contravention si demandé
        if (isset($data['with_contravention']) && $data['with_contravention'] === '1') {
            $contraventionController = new ContraventionsController();
            
            $contraventionData = [
                'dossier_id' => $vehiculeId,
                'type_dossier' => 'vehicule_plaque',
                'date_infraction' => $data['cv_date_infraction'] ?? '',
                'lieu' => $data['cv_lieu'] ?? '',
                'type_infraction' => $data['cv_type_infraction'] ?? '',
                'description' => $data['cv_description'] ?? '',
                'reference_loi' => $data['cv_reference_loi'] ?? '',
                'amende' => $data['cv_amende'] ?? 0,
                'payed' => $data['cv_payed'] ?? 0
            ];
            
            // Gestion photos contravention
            if (isset($_FILES['cv_photos'])) {
                $_FILES['photos'] = $_FILES['cv_photos'];
            }
            
            $contraventionResult = $contraventionController->create($contraventionData);
            
            if (!$contraventionResult['state']) {
                throw new Exception('Erreur lors de la création de la contravention: ' . $contraventionResult['message']);
            }
        }
        
        ORM::get_db()->commit();
        
    } catch (Exception $e) {
        ORM::get_db()->rollBack();
        $result['state'] = false;
        $result['message'] = 'Erreur: ' . $e->getMessage();
    }
    
    return $result;
}
```

#### Recherche externe DGI
```php
public function fetchFromExternal(string $plate): array
{
    $url = 'https://dgi-carterose.cd/register/' . rawurlencode($plate) . '#enregistrement';
    
    try {
        $html = $this->httpGet($url);
        $mapped = $this->parseExternalHtml($html);
        
        // Injecter la plaque si non trouvée
        if (!isset($mapped['num_plaque']) || !$mapped['num_plaque']) {
            $mapped['num_plaque'] = $plate;
        }
        
        return ['ok' => true, 'data' => $mapped];
    } catch (\Throwable $e) {
        return ['ok' => false, 'error' => 'Erreur externe: ' . $e->getMessage()];
    }
}
```

### PermisTemporaireController

#### Génération automatique de numéro
```php
private function generateNumero(): string
{
    // Format: PT-XXXXXX où XXXXXX est basé sur timestamp
    $timestamp = time();
    $uniqueNumber = str_pad(substr((string)$timestamp, -6), 6, '0', STR_PAD_LEFT);
    return "PT-{$uniqueNumber}";
}
```

#### Création permis/plaque temporaire
```php
public function create(array $data)
{
    // Génération automatique du numéro pour les plaques temporaires
    if ($motif === 'plaque_temporaire') {
        $numero = $this->generateNumero();
    } else {
        // Pour les permis temporaires, permettre saisie manuelle
        $numero = trim((string)($data['numero'] ?? ''));
        if ($numero === '') {
            $numero = $this->generateNumero();
        }
    }
    
    // Création enregistrement
    $row = ORM::for_table('permis_temporaire')->create();
    $row->cible_type = $cibleType;
    $row->cible_id = $cibleId;
    $row->numero = $numero;
    $row->motif = $motif;
    $row->date_debut = $dateDebut;
    $row->date_fin = $dateFin;
    $row->statut = 'actif';
    $row->save();
    
    // Génération PDF selon le type
    if ($cibleType === 'vehicule_plaque') {
        $pdfInfo = $this->generateTempPlatePdf([/* ... */]);
    } elseif ($cibleType === 'particulier') {
        $pdfInfo = $this->generatePermisParticulierPdfFromTemplate([/* ... */]);
    }
    
    return ['ok' => true, 'id' => $id, 'numero' => $numero, 'pdf' => $pdfInfo['public_url']];
}
```

## Routes API

### Routes principales
```php
// Création véhicule simple
$app->post('/create-vehicule-plaque', function() {
    $controller = new VehiculePlaqueController();
    return $controller->create($_POST);
});

// Création véhicule avec contravention
$app->post('/create-vehicule-with-contravention', function() {
    $controller = new VehiculePlaqueController();
    return $controller->createWithContravention($_POST);
});

// Recherche externe DGI
$app->get('/api/vehicules/fetch-externe', function() {
    $plate = $_GET['plate'] ?? '';
    $controller = new VehiculePlaqueController();
    return $controller->fetchFromExternal($plate);
});

// Recherche locale
$app->get('/vehicules/search', function() {
    $q = $_GET['q'] ?? '';
    $controller = new VehiculePlaqueController();
    return ['ok' => true, 'items' => $controller->searchByPlate($q)];
});

// Création permis/plaque temporaire
$app->post('/permis-temporaire/create', function() {
    $controller = new PermisTemporaireController();
    return $controller->create($_POST);
});

// Sauvegarde PDF sur serveur
$app->post('/permis-temporaire/{id}/save-pdf', function($id) {
    $controller = new PermisTemporaireController();
    return $controller->savePdfToServer($id);
});

// Affichage PDF plaque temporaire
$app->get('/plaque-temporaire/display', function() {
    $id = $_GET['id'] ?? 0;
    // Afficher la page de prévisualisation
    include 'views/plaque_temporaire_display.php';
});

// Routes contraventions
$app->post('/contravention/create', function() {
    $controller = new ContraventionsController();
    return $controller->create($_POST);
});

$app->get('/contravention/display', function() {
    $id = $_GET['id'] ?? 0;
    // Afficher la page de prévisualisation contravention
    include 'views/contravention_display.php';
});

$app->post('/contravention/{id}/save-pdf', function($id) {
    $controller = new ContraventionsController();
    return $controller->savePdfToServer($id);
});
```

## Workflow Utilisateur

### Création de véhicule simple
1. Utilisateur ouvre le modal de création
2. Remplit les champs obligatoires (marque, couleur)
3. Optionnellement : ajoute images, infos techniques, assurance
4. Clique "Enregistrer le véhicule"
5.d
### Création avec contravention
1. Utilisateur active le switch "Attribuer directement une contravention"
2. Section contravention s'affiche
3. Remplit les champs de contravention (date, lieu, type, montant)
4. Optionnellement : ajoute photos de contravention
5. Clique "Enregistrer le véhicule et créer la contravention"
6. Transaction : véhicule + contravention créés ensemble
7. **Ouverture automatique de la prévisualisation de contravention**
8. **Page de prévisualisation avec génération PDF côté client**
9. **Sauvegarde automatique du PDF sur le serveur**

### Recherche de plaque
1. Utilisateur saisit une plaque d'immatriculation
2. Clique "Rechercher"
3. Système cherche d'abord en base locale
4. Si non trouvé, interroge l'API DGI externe
5. Données récupérées pré-remplissent le formulaire

### Génération plaque temporaire
1. Depuis le détail d'un véhicule, clic "Plaque temporaire"
2. Modal avec dates de validité
3. Numéro généré automatiquement (format PT-XXXXXX)
4. Création en base + génération PDF
5. Ouverture page de prévisualisation avec possibilité d'impression

## Sécurité et Validation

### Validation côté client
- Taille des fichiers (8MB max par image)
- Types de fichiers autorisés (JPG, PNG, GIF)
- Validation des dates (expiration > validité)
- Champs obligatoires marqués visuellement

### Validation côté serveur
- Vérification unicité des plaques d'immatriculation
- Validation des types MIME des fichiers
- Sanitisation des données d'entrée
- Gestion des transactions pour cohérence

### Gestion des erreurs
- Try/catch avec rollback de transaction
- Messages d'erreur explicites
- Logging des activités avec ActivityLogger
- Validation des permissions utilisateur

## Stockage des fichiers

### Structure des dossiers
```
uploads/
├── vehicules/           # Images des véhicules
│   └── vehicule_[uniqid]_[timestamp].[ext]
├── contraventions/      # Photos de contraventions
│   └── contravention_[id]_[timestamp].[ext]
└── permis_temporaire/   # PDFs des permis/plaques temporaires
    ├── permis_temporaire_[numero].pdf
    └── plaque_temporaire_[numero].pdf
```

### Nommage des fichiers
- Images véhicules : `vehicule_[uniqid]_[timestamp].[ext]`
- Photos contraventions : `contravention_[id]_[timestamp].[ext]`
- PDFs permis : `permis_temporaire_[numero].pdf`
- PDFs plaques : `plaque_temporaire_[numero].pdf`

## Génération PDF

### Plaque temporaire
```php
private function generateTempPlatePdf(array $data)
{
    // Template HTML spécialisé
    include __DIR__ . '/../views/pdf/plaque_temporaire.php';
    $html = ob_get_clean();
    
    $dompdf = new Dompdf(['isRemoteEnabled' => true]);
    $dompdf->loadHtml($html);
    $dompdf->setPaper('A4', 'landscape');
    $dompdf->render();
    
    // Sauvegarde dans uploads/permis_temporaire/
    $filename = 'plaque_temporaire_' . $data['numero'] . '.pdf';
    // ...
}
```

### Permis temporaire
```php
private function generatePermisParticulierPdfFromTemplate(array $data)
{
    // Récupération données particulier
    $part = ORM::for_table('particuliers')->find_one($data['cible_id']);
    
    // Template format carte
    include __DIR__ . '/../views/permis_tmp_filled.php';
    $html = ob_get_clean();
    
    $dompdf = new Dompdf(['isRemoteEnabled' => true]);
    $dompdf->loadHtml($html);
    $dompdf->setPaper([0, 0, 500, 315], 'landscape'); // Format carte
    $dompdf->render();
    
    // Sauvegarde
    $filename = 'permis_temporaire_' . $data['numero'] . '.pdf';
    // ...
}
```

### Contravention (génération côté client)
Le système utilise une approche hybride pour les contraventions :

#### Backend - ContraventionsController
```php
public function create($data)
{
    // 1. Création de la contravention en base
    $contravention = ORM::for_table('contraventions')->create();
    $contravention->dossier_id = $data['dossier_id'];
    $contravention->type_dossier = $data['type_dossier']; // 'vehicule_plaque'
    $contravention->date_infraction = str_replace('T', ' ', $data['date_infraction']);
    $contravention->lieu = $data['lieu'] ?? '';
    $contravention->type_infraction = $data['type_infraction'] ?? '';
    $contravention->description = $data['description'] ?? '';
    $contravention->reference_loi = $data['reference_loi'] ?? '';
    $contravention->amende = $data['amende'] ?? 0;
    $contravention->payed = $data['payed'] ?? 0;
    $contravention->save();
    
    // 2. Gestion des photos
    $this->handlePhotoUploads($contravention->id());
    
    // 3. Retour de l'URL de prévisualisation
    $result['preview_url'] = '/contravention/display?id=' . $contravention->id;
    
    return $result;
}

// Sauvegarde PDF généré côté client
public function savePdfToServer($id)
{
    // Vérification du fichier PDF uploadé
    if (!isset($_FILES['pdf']) || $_FILES['pdf']['error'] !== UPLOAD_ERR_OK) {
        return ['ok' => false, 'error' => 'Aucun fichier PDF reçu'];
    }
    
    // Validation type MIME
    if ($_FILES['pdf']['type'] !== 'application/pdf') {
        return ['ok' => false, 'error' => 'Le fichier doit être un PDF'];
    }
    
    // Sauvegarde dans uploads/contraventions/
    $filename = 'contravention_' . $id . '.pdf';
    $destinationPath = __DIR__ . '/../uploads/contraventions/' . $filename;
    
    if (move_uploaded_file($_FILES['pdf']['tmp_name'], $destinationPath)) {
        return [
            'ok' => true,
            'pdf_path' => 'uploads/contraventions/' . $filename,
            'download_url' => '/uploads/contraventions/' . $filename
        ];
    }
    
    return ['ok' => false, 'error' => 'Erreur lors de la sauvegarde'];
}
```

#### Frontend - Génération PDF côté client
```javascript
// Page de prévisualisation contravention (contravention_display.php)
function generateAndSavePDF() {
    const element = document.getElementById('contravention-content');
    
    // Utilisation de html2canvas + jsPDF
    html2canvas(element, {
        scale: 2,
        useCORS: true,
        allowTaint: true
    }).then(canvas => {
        const imgData = canvas.toDataURL('image/png');
        const pdf = new jsPDF('p', 'mm', 'a4');
        
        const imgWidth = 210;
        const pageHeight = 295;
        const imgHeight = (canvas.height * imgWidth) / canvas.width;
        let heightLeft = imgHeight;
        let position = 0;
        
        pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight);
        heightLeft -= pageHeight;
        
        while (heightLeft >= 0) {
            position = heightLeft - imgHeight;
            pdf.addPage();
            pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight);
            heightLeft -= pageHeight;
        }
        
        // Sauvegarde sur le serveur
        const pdfBlob = pdf.output('blob');
        const formData = new FormData();
        formData.append('pdf', pdfBlob, `contravention_${contraventionId}.pdf`);
        
        fetch(`/contravention/${contraventionId}/save-pdf`, {
            method: 'POST',
            body: formData
        }).then(response => response.json())
          .then(data => {
              if (data.ok) {
                  console.log('PDF sauvegardé:', data.pdf_path);
              }
          });
    });
}
```

## Points d'attention pour Flutter Web

### Gestion des fichiers
- Flutter Web ne peut pas accéder directement au système de fichiers
- Utiliser `html.FileUploadInputElement` pour la sélection de fichiers
- Prévisualisation avec `html.Url.createObjectUrlFromBlob()`

### API REST
- Toutes les interactions doivent passer par des appels HTTP
- Utiliser `dio` ou `http` pour les requêtes
- Gestion des FormData pour l'upload de fichiers multiples

### État de l'application
- Utiliser un state management (Provider, Riverpod, Bloc)
- Gérer les états de chargement, erreur, succès
- Synchronisation entre les différents écrans

### Validation
- Implémenter la validation côté client avec Flutter
- Utiliser des packages comme `form_validator` ou `formz`
- Affichage des erreurs en temps réel

Cette documentation fournit une base complète pour recréer la fonctionnalité avec Flutter Web et une API PHP. Les concepts clés sont la gestion des fichiers multiples, les transactions de base de données, la génération de PDFs, et l'intégration avec des APIs externes.
