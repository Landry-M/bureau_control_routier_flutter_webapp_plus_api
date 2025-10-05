# Modal Détails Particulier - Plan d'Implémentation

## Objectif
Créer une modal détaillée pour les particuliers avec 3 onglets : Informations, Contraventions, et Arrestations, similaire à la modal entreprise existante.

## Fonctionnalités Requises

### 1. Structure Générale
- ✅ Modal avec TabController (3 onglets)
- ✅ En-tête avec titre et bouton fermer (croix)
- ✅ Design responsive (90% largeur, 80% hauteur)
- ✅ Thème cohérent avec l'application

### 2. Onglet "Informations"
- ✅ Affichage de toutes les informations du particulier
- ✅ **Photo du particulier** (si disponible)
- ✅ **Photos du permis recto/verso** (si disponibles)
- ✅ Champs organisés en sections logiques :
  - Informations personnelles (ID, nom, prénom, âge, sexe)
  - Coordonnées (téléphone, adresse)
  - Permis de conduire (numéro, catégorie, dates)
  - Photos (photo personnelle, permis recto, permis verso)
  - Informations supplémentaires (observations, dates)

### 3. Onglet "Contraventions"
- ✅ Table des contraventions liées au particulier
- ✅ Colonnes : ID, Date, Type, Lieu, Amende, Payé, PDF
- ✅ Switch interactif pour le statut de paiement
- ✅ Bouton œil pour visualiser les PDFs
- ✅ Gestion des états : loading, erreur, vide, données

### 4. Onglet "Arrestations"
- ✅ Table des arrestations liées au particulier
- ✅ Colonnes : ID, Date, Motif, Lieu, Statut, Actions
- ✅ Gestion des états : loading, erreur, vide, données

## Étapes d'Implémentation

### Étape 1 : Structure de Base
```dart
// Créer /lib/widgets/particulier_details_modal.dart
class ParticulierDetailsModal extends StatefulWidget {
  final Map<String, dynamic> particulier;
  
  const ParticulierDetailsModal({
    super.key,
    required this.particulier,
  });
}

class _ParticulierDetailsModalState extends State<ParticulierDetailsModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
}
```

### Étape 2 : Onglet Informations avec Photos
```dart
Widget _buildInfoTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Photos
        _buildPhotosSection(),
        
        // Informations personnelles
        _buildPersonalInfoSection(),
        
        // Coordonnées
        _buildContactSection(),
        
        // Permis de conduire
        _buildLicenseSection(),
        
        // Informations supplémentaires
        _buildAdditionalInfoSection(),
      ],
    ),
  );
}

Widget _buildPhotosSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Photos', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Row(
        children: [
          // Photo du particulier
          _buildPhotoCard('Photo', widget.particulier['photo']),
          const SizedBox(width: 12),
          // Permis recto
          _buildPhotoCard('Permis Recto', widget.particulier['permis_recto']),
          const SizedBox(width: 12),
          // Permis verso
          _buildPhotoCard('Permis Verso', widget.particulier['permis_verso']),
        ],
      ),
    ],
  );
}

Widget _buildPhotoCard(String title, String? imagePath) {
  return Container(
    width: 120,
    height: 160,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          child: imagePath != null && imagePath.isNotEmpty
              ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    '${ApiConfig.baseUrl}/$imagePath',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 40),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                )
              : Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 40),
                ),
        ),
        Container(
          height: 40,
          padding: const EdgeInsets.all(4),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
}
```

### Étape 3 : Onglet Contraventions
```dart
Widget _buildContraventionsTab() {
  // Similaire à la modal entreprise
  // Table avec colonnes : ID, Date, Type, Lieu, Amende, Payé, PDF
  // Switch pour le statut de paiement
  // Bouton œil pour les PDFs
}

Future<void> _loadContraventions() async {
  // API call vers /contraventions/particulier/{id}
}
```

### Étape 4 : Onglet Arrestations
```dart
Widget _buildArrestationsTab() {
  // Table avec colonnes : ID, Date, Motif, Lieu, Statut, Actions
  // Gestion des états similaire aux contraventions
}

Future<void> _loadArrestations() async {
  // API call vers /arrestations/particulier/{id}
}
```

### Étape 5 : Endpoints API Backend

#### Contraventions Particulier
```php
// Dans /api/routes/index.php
$router->get('/contraventions/particulier/{id}', function($id) {
    $controller = new ContraventionController();
    return $controller->getByParticulier($id);
});
```

#### Arrestations Particulier
```php
// Dans /api/routes/index.php
$router->get('/arrestations/particulier/{id}', function($id) {
    $controller = new ArrestationController();
    return $controller->getByParticulier($id);
});
```

#### Méthodes Controller
```php
// Dans ContraventionController.php
public function getByParticulier($particulierId) {
    $sql = "SELECT * FROM contraventions 
            WHERE dossier_id = :dossier_id 
            AND type_dossier = 'particulier' 
            ORDER BY date_infraction DESC";
    // ... implémentation
}

// Dans ArrestationController.php
public function getByParticulier($particulierId) {
    $sql = "SELECT * FROM arrestations 
            WHERE particulier_id = :particulier_id 
            ORDER BY date_arrestation DESC";
    // ... implémentation
}
```

### Étape 6 : Intégration dans AllRecordsScreen
```dart
// Dans /lib/screens/all_records_screen.dart
void _showParticulierDetailsModal(Map<String, dynamic> particulier) {
  showDialog(
    context: context,
    builder: (context) => ParticulierDetailsModal(particulier: particulier),
  );
}

// Remplacer l'ancien bouton "Voir détails" par :
IconButton(
  onPressed: () => _showParticulierDetailsModal(particulier),
  icon: const Icon(Icons.visibility),
  tooltip: 'Voir détails',
),
```

## Structure des Données

### Table particuliers
- `id`, `nom`, `prenom`, `age`, `sexe`
- `telephone`, `adresse`
- `numero_permis`, `categorie_permis`, `date_delivrance`, `date_expiration`
- `photo`, `permis_recto`, `permis_verso`
- `observations`, `created_at`, `updated_at`

### Table contraventions
- Filtrées par `dossier_id = particulier.id` ET `type_dossier = 'particulier'`

### Table arrestations
- Filtrées par `particulier_id = particulier.id`

## Fichiers à Créer/Modifier

### Nouveaux Fichiers
- `/lib/widgets/particulier_details_modal.dart` - Modal principale
- Endpoints API dans `/api/routes/index.php`
- Méthodes dans `/api/controllers/ContraventionController.php`
- Méthodes dans `/api/controllers/ArrestationController.php`

### Fichiers à Modifier
- `/lib/screens/all_records_screen.dart` - Intégration de la modal
- Import de la nouvelle modal

## Fonctionnalités Avancées

### Gestion des Photos
- Prévisualisation des 3 types de photos (personnelle, permis recto/verso)
- Clic sur photo pour affichage plein écran
- Gestion d'erreurs de chargement avec icônes de remplacement
- Loading states pour les images

### Tables Interactives
- Switch pour statut de paiement des contraventions
- Boutons d'action pour visualiser les PDFs
- Tri par date décroissante
- Gestion des cas vides avec interfaces informatives

### UX/UI
- Design cohérent avec la modal entreprise
- Toastification pour les notifications
- États de chargement avec indicateurs visuels
- Messages d'erreur explicites avec boutons de réessai

## Notes Techniques

### Gestion des Images
```dart
// URL complète pour les images
final imageUrl = '${ApiConfig.baseUrl}/${widget.particulier['photo']}';

// Gestion d'erreurs
errorBuilder: (context, error, stackTrace) {
  return Container(
    color: Colors.grey.shade200,
    child: const Icon(Icons.broken_image, size: 40),
  );
}
```

### API Responses
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "date_infraction": "2024-01-15",
      "type_infraction": "Excès de vitesse",
      "lieu": "Avenue Lumumba",
      "amende": "50000",
      "payed": "non",
      "pdf_path": "uploads/contraventions/cv_123.pdf"
    }
  ]
}
```

## Priorités d'Implémentation

1. **Haute Priorité**
   - Structure de base de la modal
   - Onglet Informations avec photos
   - Endpoints API pour contraventions et arrestations

2. **Moyenne Priorité**
   - Onglet Contraventions avec table interactive
   - Onglet Arrestations avec table

3. **Basse Priorité**
   - Fonctionnalités avancées (zoom photos, etc.)
   - Optimisations de performance

## État Actuel
- ❌ Modal non créée
- ❌ Endpoints API manquants
- ❌ Intégration dans AllRecordsScreen manquante

## Prochaines Actions
1. Créer la structure de base de la modal
2. Implémenter l'onglet Informations avec photos
3. Créer les endpoints API backend
4. Implémenter les onglets Contraventions et Arrestations
5. Intégrer dans AllRecordsScreen
6. Tests et ajustements finaux
