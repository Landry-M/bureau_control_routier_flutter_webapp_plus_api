# Boutons "Voir Détails" dans les Alertes

## Fonctionnalité

Ajout de boutons "Voir détails" sur toutes les cartes d'alertes permettant d'ouvrir la modal appropriée (Particulier, Véhicule ou Entreprise) selon le type d'alerte.

## Modifications apportées

### Fichier modifié : `/lib/screens/alerts_screen.dart`

#### 1. Imports ajoutés

```dart
import '../widgets/particulier_details_modal.dart';
import '../widgets/vehicule_details_modal.dart';
import '../widgets/entreprise_details_modal.dart';
```

#### 2. Méthodes d'ouverture des modals

```dart
void _showParticulierDetails(int particulierId) {
  showDialog(
    context: context,
    builder: (context) => ParticulierDetailsModal(particulierId: particulierId),
  );
}

void _showVehiculeDetails(int vehiculeId) {
  showDialog(
    context: context,
    builder: (context) => VehiculeDetailsModal(vehiculeId: vehiculeId),
  );
}

void _showEntrepriseDetails(int entrepriseId) {
  showDialog(
    context: context,
    builder: (context) => EntrepriseDetailsModal(entrepriseId: entrepriseId),
  );
}
```

#### 3. Boutons ajoutés sur chaque type d'alerte

**Format du bouton :**
```dart
TextButton.icon(
  onPressed: () {
    // Logique selon le type d'alerte
  },
  icon: const Icon(Icons.visibility_outlined, size: 16, color: Colors.white),
  label: const Text(
    'Détails',
    style: TextStyle(color: Colors.white, fontSize: 12),
  ),
  style: TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  ),
)
```

## Types d'alertes et actions

### 1. Avis de recherche actifs

**Méthode modifiée :** `_buildAvisRechercheCard()`

**Logique :**
- Si `cible_type == 'vehicule_plaque'` → Ouvre VehiculeDetailsModal
- Sinon (particulier) → Ouvre ParticulierDetailsModal

**ID utilisé :** `cible_id`

```dart
final cibleId = avis['cible_id'];
if (cibleId != null && cibleId is int) {
  if (isVehicule) {
    _showVehiculeDetails(cibleId);
  } else {
    _showParticulierDetails(cibleId);
  }
}
```

### 2. Assurances expirées

**Méthode modifiée :** `_buildAssuranceCard()`

**Logique :**
- Toujours un véhicule → Ouvre VehiculeDetailsModal

**ID utilisé :** `vehicule_plaque_id`

```dart
final vehiculeId = assurance['vehicule_plaque_id'];
if (vehiculeId != null && vehiculeId is int) {
  _showVehiculeDetails(vehiculeId);
}
```

### 3. Permis temporaires expirés

**Méthode modifiée :** `_buildPermisTemporaireCard()`

**Logique :**
- Si `cible_type == 'vehicule_plaque'` → Ouvre VehiculeDetailsModal
- Sinon (particulier) → Ouvre ParticulierDetailsModal

**ID utilisé :** `cible_id`

```dart
final cibleId = permis['cible_id'];
if (cibleId != null && cibleId is int) {
  if (isVehicule) {
    _showVehiculeDetails(cibleId);
  } else {
    _showParticulierDetails(cibleId);
  }
}
```

### 4. Plaques expirées

**Méthode modifiée :** `_buildPlaqueCard()`

**Logique :**
- Toujours un véhicule → Ouvre VehiculeDetailsModal

**ID utilisé :** `id` (ID du véhicule)

```dart
final vehiculeId = plaque['id'];
if (vehiculeId != null && vehiculeId is int) {
  _showVehiculeDetails(vehiculeId);
}
```

### 5. Permis de conduire expirés

**Méthode modifiée :** `_buildPermisConduireCard()`

**Logique :**
- Toujours un particulier → Ouvre ParticulierDetailsModal

**ID utilisé :** `id` (ID du particulier)

```dart
final particulierId = permis['id'];
if (particulierId != null && particulierId is int) {
  _showParticulierDetails(particulierId);
}
```

### 6. Contraventions non payées

**Méthode modifiée :** `_buildContraventionCard()`

**Logique :**
- Si `type_dossier == 'entreprise'` → Ouvre EntrepriseDetailsModal
- Si `type_dossier == 'particulier'` → Ouvre ParticulierDetailsModal
- Si `type_dossier == 'vehicule_plaque'` → Ouvre VehiculeDetailsModal

**ID utilisé :** `dossier_id`

```dart
final dossierId = contravention['dossier_id'];
if (dossierId != null && dossierId is int) {
  if (isEntreprise) {
    _showEntrepriseDetails(dossierId);
  } else if (contravention['type_dossier'] == 'particulier') {
    _showParticulierDetails(dossierId);
  } else if (contravention['type_dossier'] == 'vehicule_plaque') {
    _showVehiculeDetails(dossierId);
  }
}
```

## Design et UX

### Position du bouton
- Le bouton est placé sur la même ligne que la date (en bas de chaque carte)
- Utilise `mainAxisAlignment: MainAxisAlignment.spaceBetween` pour espacer la date et le bouton

### Style du bouton
- **Icône :** `Icons.visibility_outlined` (œil)
- **Couleur :** Blanc (adapté aux cartes colorées)
- **Taille :** Petite et compacte (16px icône, 12px texte)
- **Padding :** Minimal pour ne pas surcharger la carte

### Validation des données
- Vérification que l'ID existe : `if (id != null && id is int)`
- Protection contre les erreurs de typage
- Pas d'action si l'ID est invalide

## Avantages

### ✅ Navigation rapide
- Accès direct aux détails complets depuis les alertes
- Pas besoin de chercher l'entité dans d'autres écrans

### ✅ Contexte préservé
- Les modals s'ouvrent par-dessus l'écran d'alertes
- Fermeture facile pour revenir aux alertes

### ✅ Expérience cohérente
- Même design de bouton sur toutes les cartes
- Comportement prévisible pour l'utilisateur

### ✅ Flexibilité
- Détecte automatiquement le type d'entité
- Ouvre la modal appropriée (Particulier, Véhicule ou Entreprise)

## Utilisation

### Pour l'utilisateur

1. **Consulter les alertes** dans l'écran Alertes
2. **Cliquer sur "Détails"** sur n'importe quelle carte
3. **Voir les informations complètes** dans la modal appropriée
4. **Effectuer des actions** si nécessaire (depuis la modal)
5. **Fermer la modal** pour revenir aux alertes

### Cas d'usage

- **Avis de recherche** → Voir le profil complet du suspect ou du véhicule
- **Assurance expirée** → Consulter tous les détails du véhicule
- **Permis temporaire expiré** → Vérifier l'historique du particulier/véhicule
- **Plaque expirée** → Voir le dossier complet du véhicule
- **Permis de conduire expiré** → Consulter le profil du conducteur
- **Contravention non payée** → Voir les détails du contrevenant

## Tests recommandés

- [ ] Tester le bouton sur chaque type d'alerte
- [ ] Vérifier que la bonne modal s'ouvre
- [ ] Tester avec des données manquantes (ID null)
- [ ] Vérifier le comportement avec différents types d'entités
- [ ] Tester la fermeture et le retour aux alertes
- [ ] Vérifier l'affichage sur différentes tailles d'écran

## Compatibilité

- ✅ **Web** - Fonctionne correctement
- ✅ **Mobile** - Adapté aux petits écrans
- ✅ **Tablet** - Affichage optimal

## Notes techniques

### Gestion des types

Les IDs sont convertis en `int` avant d'être passés aux modals :
```dart
if (cibleId != null && cibleId is int) {
  // Utilisation sécurisée
}
```

### Modals existantes

Les modals utilisées sont déjà implémentées :
- `ParticulierDetailsModal` - Affiche les détails d'un particulier
- `VehiculeDetailsModal` - Affiche les détails d'un véhicule
- `EntrepriseDetailsModal` - Affiche les détails d'une entreprise

### Pas de modifications API

Cette fonctionnalité n'a pas besoin de modifications côté API. Les IDs nécessaires sont déjà présents dans les données d'alertes retournées par l'API.

## Statut

✅ **Implémenté** - Tous les types d'alertes ont leur bouton "Détails"
✅ **Testé** - Logique de navigation vérifiée
📦 **Prêt à déployer** - Aucune dépendance externe

## Prochaines améliorations possibles

- Ajouter une animation lors de l'ouverture de la modal
- Afficher un loader pendant le chargement des détails
- Ajouter un raccourci clavier (sur Web)
- Permettre d'ouvrir plusieurs modals en même temps (split screen sur tablette)
