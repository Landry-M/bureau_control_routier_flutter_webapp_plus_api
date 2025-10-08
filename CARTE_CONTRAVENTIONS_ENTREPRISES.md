# Fonctionnalité Carte pour Contraventions d'Entreprises

## 📍 Ajout du bouton "Voir sur carte" dans la modal entreprise

### Problème résolu
L'utilisateur ne voyait pas le bouton d'action pour voir l'emplacement de la contravention sur la carte dans la modal de détails des entreprises, contrairement à la modal des particuliers.

### Solution implémentée

#### 1. **Imports ajoutés**
```dart
import '../services/notification_service.dart';
import 'contravention_map_viewer.dart';
```

#### 2. **Méthode `_viewOnMap` ajoutée**
```dart
void _viewOnMap(Map<String, dynamic> contravention) {
  final latitude = contravention['latitude'];
  final longitude = contravention['longitude'];
  
  if (latitude != null && longitude != null) {
    showDialog(
      context: context,
      builder: (context) => ContraventionMapViewer(
        contravention: contravention,
      ),
    );
  } else {
    NotificationService.error(
      context, 
      'Aucune localisation disponible pour cette contravention'
    );
  }
}
```

#### 3. **Colonne "Carte" ajoutée à la table**
```dart
DataColumn(
  label: Expanded(
    flex: 1,
    child: Text('Carte',
        style: TextStyle(fontWeight: FontWeight.bold)),
  )
),
```

#### 4. **Cellule avec bouton carte ajoutée**
```dart
DataCell(
  Container(
    width: double.infinity,
    alignment: Alignment.center,
    child: IconButton(
      onPressed: () => _viewOnMap(contravention),
      icon: const Icon(Icons.map, size: 18),
      tooltip: 'Voir sur la carte',
      style: IconButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        minimumSize: const Size(32, 32),
        padding: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    ),
  ),
),
```

### Fonctionnalités

#### ✅ **Cohérence avec les particuliers**
- Même fonctionnalité que dans `particulier_details_modal.dart`
- Interface utilisateur identique
- Gestion d'erreurs cohérente

#### ✅ **Gestion des cas d'erreur**
- Vérification de la présence des coordonnées
- Message d'erreur si pas de localisation disponible
- Utilisation de `NotificationService` pour les notifications

#### ✅ **Design cohérent**
- Bouton bleu avec icône carte
- Tooltip informatif
- Style cohérent avec le bouton PDF

### Structure de la table des contraventions

| Colonne | Description | Actions |
|---------|-------------|---------|
| **ID** | Numéro de contravention | - |
| **Date** | Date de l'infraction | - |
| **Type** | Type d'infraction | - |
| **Lieu** | Lieu de l'infraction | - |
| **Amende** | Montant de l'amende | - |
| **Payé** | Statut de paiement | Toggle switch |
| **PDF** | Document PDF | Bouton voir PDF |
| **Carte** | Localisation GPS | **🆕 Bouton voir carte** |

### Utilisation

1. **Ouvrir la modal entreprise** depuis n'importe quel écran
2. **Aller à l'onglet "Contraventions"**
3. **Cliquer sur l'icône carte** (🗺️) dans la dernière colonne
4. **Voir la localisation** sur Google Maps avec marqueur

### Prérequis

- La contravention doit avoir des coordonnées latitude/longitude
- Les coordonnées sont enregistrées lors de la création via le formulaire avec sélection de carte
- Le widget `ContraventionMapViewer` doit être disponible

### Tests

- **Test unitaire** : `test_entreprise_carte_button.dart`
- **Test manuel** : Créer une contravention avec localisation, puis vérifier dans la modal entreprise

### Cohérence dans l'application

Cette fonctionnalité est maintenant disponible dans :

1. ✅ **Modal particulier** (`particulier_details_modal.dart`)
2. ✅ **Modal entreprise** (`entreprise_details_modal.dart`)
3. ✅ **Formulaires de création** (avec sélection sur carte)
4. ✅ **Page de prévisualisation** (avec coordonnées affichées)

### Prochaines améliorations possibles

- [ ] Ajouter la fonctionnalité dans d'autres écrans de liste
- [ ] Permettre la modification de la localisation
- [ ] Afficher un aperçu miniature de la carte dans la table
- [ ] Ajouter des filtres par zone géographique
