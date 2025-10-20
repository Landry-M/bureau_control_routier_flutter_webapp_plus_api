# Génération automatique de PDF pour les avis de recherche

## Vue d'ensemble

Système complet de génération automatique de PDF pour les avis de recherche avec design moderne et professionnel, prêt pour l'impression et l'affichage public.

## Fichiers créés

### Backend (API)
- **`/api/controllers/AvisRecherchePdfController.php`** - Contrôleur de génération de PDF
- **`/api/database/add_pdf_path_to_avis_recherche.sql`** - Script SQL pour la colonne pdf_path

### Modifications
- **`/api/controllers/AvisRechercheController.php`** - Génération automatique du PDF après création

## Caractéristiques du PDF

### Design moderne et professionnel
✅ **En-tête avec identité visuelle**
- Drapeau de la RDC (gauche)
- Titre "AVIS DE RECHERCHE" centré
- Logo du bureau (droite)
- Sous-titre "République Démocratique du Congo"

✅ **Bannière de priorité**
- Couleur dynamique selon le niveau :
  - Vert pour "Faible"
  - Orange pour "Moyen"
  - Rouge pour "Élevé"

✅ **Sections d'information**
- **Pour particuliers :**
  - Nom complet
  - Téléphone
  - Date de naissance
  - Adresse
  
- **Pour véhicules :**
  - Plaque d'immatriculation (en gros et en rouge)
  - Marque et modèle
  - Couleur
  - Année
  - Numéro de châssis (si fourni)

✅ **Motif de la recherche**
- Zone encadrée en jaune avec icône
- Texte formaté avec retours à la ligne

✅ **Photos**
- Grille responsive (3 colonnes)
- Images converties en base64 pour inclusion dans le PDF
- Masquée automatiquement si aucune image fournie

✅ **Section d'avertissement**
- Fond rouge avec informations de contact
- Numéro d'urgence
- Message de sécurité

✅ **Pied de page**
- Coordonnées du bureau
- Mention légale
- Design professionnel

### Fonctionnalités techniques

#### Génération automatique
Le PDF est généré **automatiquement** après chaque création d'avis de recherche via :
- `EmettreAvisRechercheModal`
- `SosAvisParticulierModal`
- `SosAvisVehiculeModal`

#### Technologie utilisée
- **wkhtmltopdf** (si disponible) : Conversion HTML vers PDF haute qualité
- **Fallback HTML** : Si wkhtmltopdf n'est pas installé

#### Gestion des images
- Conversion automatique en base64
- Support formats : PNG, JPEG, GIF, WebP
- Photos de l'avis de recherche incluses
- Photo du particulier (si disponible)

#### Stockage
- Dossier : `/api/uploads/avis_recherche_pdf/`
- Format du nom : `avis_recherche_{ID}_{DATE}_{ HEURE}.pdf`
- Chemin stocké dans la colonne `pdf_path`

## Installation

### 1. Exécuter la migration SQL

```bash
cd /Users/apple/Documents/dev/flutter/bcr
mysql -u votre_user -p control_routier < api/database/add_pdf_path_to_avis_recherche.sql
```

Ou via phpMyAdmin :
1. Sélectionner la base de données `control_routier`
2. Aller dans l'onglet SQL
3. Exécuter le contenu du fichier `add_pdf_path_to_avis_recherche.sql`

### 2. Installer wkhtmltopdf (recommandé pour de meilleurs PDF)

#### macOS
```bash
brew install wkhtmltopdf
```

#### Ubuntu/Debian
```bash
sudo apt-get install wkhtmltopdf
```

#### Windows
Télécharger depuis : https://wkhtmltopdf.org/downloads.html

### 3. Créer le dossier d'uploads

Le dossier sera créé automatiquement, mais vous pouvez le créer manuellement :

```bash
mkdir -p api/uploads/avis_recherche_pdf
chmod 777 api/uploads/avis_recherche_pdf
```

### 4. Vérifier les assets

Assurez-vous que ces fichiers existent :
- `/api/assets/images/drapeau.png` - Drapeau de la RDC
- `/api/assets/images/logo.png` - Logo du bureau

## Utilisation

### Génération automatique

Le PDF est généré **automatiquement** lors de l'émission d'un avis de recherche. Aucune action supplémentaire n'est requise.

### Génération manuelle (si nécessaire)

Si vous devez régénérer le PDF pour un avis existant :

```php
require_once 'api/controllers/AvisRecherchePdfController.php';

$pdfController = new AvisRecherchePdfController();
$result = $pdfController->generatePdf($avisId);

if ($result['success']) {
    echo "PDF généré : " . $result['pdf_url'];
}
```

### Accéder au PDF

Une fois généré, le PDF est accessible via :
```
http://votre-domaine.com/{pdf_path}
```

Exemple :
```
http://votre-domaine.com/api/uploads/avis_recherche_pdf/avis_recherche_1_2025-10-14_05-45-00.pdf
```

## Structure du PDF

```
┌─────────────────────────────────────┐
│  [Drapeau]  AVIS DE RECHERCHE [Logo]│
│  République Démocratique du Congo   │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│    NIVEAU DE PRIORITÉ: ÉLEVÉ        │  ← Couleur dynamique
└─────────────────────────────────────┘
│                                     │
│  Avis N° 000001                     │
│  Émis le 14/10/2025 par username    │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 👤 PERSONNE RECHERCHÉE      │   │
│  │  Nom: ...   Téléphone: ...  │   │
│  │  Date naiss: ...  Adresse...│   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📋 MOTIF DE LA RECHERCHE    │   │
│  │  Description du motif...    │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📸 PHOTOS                   │   │
│  │  [IMG] [IMG] [IMG]          │   │
│  │  [IMG] [IMG] [IMG]          │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ ⚠️ INFORMATION IMPORTANTE    │   │
│  │  Téléphone: +243 XXX XXX    │   │
│  └─────────────────────────────┘   │
│                                     │
│  Bureau de Contrôle Routier - RDC  │
└─────────────────────────────────────┘
```

## Personnalisation

### Modifier le design

Éditez le fichier `/api/controllers/AvisRecherchePdfController.php`, méthode `generatePdfHtml()` :

```php
private function generatePdfHtml($avis) {
    // Modifier le HTML et le CSS ici
}
```

### Changer les couleurs de priorité

Dans la méthode `generatePdfHtml()` :

```php
$niveauColor = match($avis['niveau']) {
    'faible' => '#28a745',   // Vert
    'moyen' => '#ff9800',    // Orange
    'élevé' => '#dc3545',    // Rouge
    default => '#ff9800'
};
```

### Ajouter un QR Code

Installez une bibliothèque QR Code PHP et ajoutez dans `generatePdfHtml()` :

```php
// Générer QR Code avec l'URL de l'avis
$qrCodeUrl = "https://controle-routier.gov.cd/avis/" . $avis['id'];
// Inclure l'image du QR Code dans le PDF
```

## Dépannage

### PDF non généré

1. **Vérifier les logs** :
```bash
tail -f /var/log/apache2/error.log
# ou
tail -f /var/log/nginx/error.log
```

2. **Vérifier wkhtmltopdf** :
```bash
which wkhtmltopdf
wkhtmltopdf --version
```

3. **Vérifier les permissions** :
```bash
ls -la api/uploads/avis_recherche_pdf/
chmod 777 api/uploads/avis_recherche_pdf/
```

### Images ne s'affichent pas

1. Vérifier que les fichiers existent :
```bash
ls -la api/assets/images/drapeau.png
ls -la api/assets/images/logo.png
```

2. Vérifier les chemins dans le code

3. S'assurer que les images uploadées sont accessibles

### PDF de mauvaise qualité

Si wkhtmltopdf n'est pas installé, le système crée un fichier HTML. Pour améliorer :

1. Installer wkhtmltopdf (voir section Installation)
2. Ou utiliser une bibliothèque PHP alternative (DomPDF, TCPDF, mPDF)

## Améliorations futures possibles

- [ ] QR Code pointant vers l'avis en ligne
- [ ] Numéro de téléphone d'urgence configurable
- [ ] Support multi-langues
- [ ] Filigrane personnalisable
- [ ] Compression automatique des images
- [ ] Version A3 pour affichage grand format
- [ ] Export en différents formats (PNG, JPG pour réseaux sociaux)
- [ ] Envoi automatique par email aux autorités
- [ ] Statistiques de consultation du PDF

## Sécurité

- ✅ Les chemins de fichiers sont sécurisés avec `escapeshellarg()`
- ✅ Le contenu HTML est échappé avec `htmlspecialchars()`
- ✅ Les uploads sont stockés hors de la racine web publique
- ✅ Validation des extensions d'images
- ✅ Noms de fichiers uniques avec timestamp

## Performance

- Le PDF est généré **une seule fois** à la création
- Les images sont converties en base64 (augmente la taille mais évite les liens externes)
- Le fichier PDF est stocké et réutilisable
- Pas de régénération inutile

## Support

Pour toute question ou problème, consultez :
- Documentation API : `/api/docs/`
- Logs d'erreur : `/var/log/`
- Fichier AVIS_RECHERCHE_IMAGES_CHASSIS.md

---

**Note** : Ce système est conçu pour fonctionner avec ou sans wkhtmltopdf. Pour une qualité optimale, l'installation de wkhtmltopdf est fortement recommandée.
