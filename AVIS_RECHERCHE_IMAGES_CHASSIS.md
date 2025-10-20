# Amélioration de la fonctionnalité Avis de Recherche

## Résumé des modifications

Ce document décrit les modifications apportées au système d'avis de recherche pour ajouter la possibilité de télécharger des images et de renseigner le numéro de châssis pour les véhicules.

## Modifications effectuées

### 1. Base de données

**Fichiers créés :**
- `/api/database/add_avis_recherche_images_chassis.sql` - Script SQL pour ajouter les colonnes
- `/api/database/migrate_avis_recherche_images.php` - Script PHP de migration

**Nouvelles colonnes dans la table `avis_recherche` :**
- `images` (TEXT NULL) : Stocke les chemins des images au format JSON
- `numero_chassis` (VARCHAR(100) NULL) : Numéro de châssis du véhicule (pour les avis de recherche de véhicules uniquement)
- Index ajouté sur `numero_chassis` pour optimiser les recherches

**Exécution de la migration :**
```bash
php api/database/migrate_avis_recherche_images.php
```

### 2. Backend (API)

**Fichier modifié :** `/api/controllers/AvisRechercheController.php`

**Modifications principales :**
- Ajout de la méthode `uploadImages()` pour gérer l'upload multiple d'images
- Modification de la méthode `create()` pour :
  - Accepter les fichiers images via `$_FILES['images']`
  - Accepter le numéro de châssis via `$data['numero_chassis']`
  - Stocker les chemins des images en format JSON dans la base de données
  - Créer automatiquement le dossier `/uploads/avis_recherche/` si nécessaire
  - Valider les extensions d'images (jpg, jpeg, png, gif, webp)

**Sécurité :**
- Validation des extensions de fichiers
- Noms de fichiers uniques générés avec `uniqid()` + timestamp
- Permissions appropriées sur le dossier d'upload (777)

### 3. Frontend (Flutter)

**Fichier modifié :** `/lib/widgets/emettre_avis_recherche_modal.dart`

**Modifications principales :**

#### Correction du dépassement
- Hauteur de la modal augmentée de **65%** à **75%** de la hauteur de l'écran (+10%)
- Cela résout le problème de dépassement de 46 pixels

#### Ajout de l'upload d'images
- Import de `image_picker` et `ImageUtils`
- Nouveau contrôleur : `_numeroChassisController`
- Nouvelle liste : `_selectedImages` pour stocker les images sélectionnées
- Méthode `_pickImages()` : Permet de sélectionner plusieurs images
- Méthode `_removeImage()` : Permet de supprimer une image sélectionnée
- Section UI `_buildImagesSection()` :
  - Bouton "Ajouter des images"
  - Aperçu des images sélectionnées (100x100px)
  - Bouton de suppression sur chaque image
  - Compteur d'images sélectionnées

#### Ajout du champ numéro de châssis
- Section UI `_buildNumeroChassisSection()` :
  - Affiché uniquement pour les avis de recherche de véhicules (`cibleType == 'vehicule_plaque'`)
  - Champ optionnel avec icône et placeholder
  - TextFormField avec préfixe Icon(Icons.numbers)

#### Modification de la soumission
- Passage de `http.post()` à `http.MultipartRequest()` pour supporter l'upload de fichiers
- Ajout des fichiers images dans la requête avec `ImageUtils.createMultipartFile()`
- Ajout du numéro de châssis dans les champs du formulaire (si renseigné)
- Compatibilité web et mobile grâce à `ImageUtils`

### 4. Structure des fichiers

**Nouveaux dossiers créés :**
```
/uploads/avis_recherche/
```

**Format de stockage des images :**
Les chemins d'images sont stockés en JSON dans la base de données :
```json
["uploads/avis_recherche/abc123_1234567890.jpg", "uploads/avis_recherche/def456_1234567890.png"]
```

## Utilisation

### Pour les avis de recherche de particuliers :
1. Cliquer sur "Émettre un avis de recherche" depuis un particulier
2. Remplir le motif (obligatoire)
3. Sélectionner le niveau de priorité (faible, moyen, élevé)
4. **[NOUVEAU]** Cliquer sur "Ajouter des images" pour joindre des photos (optionnel)
5. Soumettre le formulaire

### Pour les avis de recherche de véhicules :
1. Cliquer sur "Émettre un avis de recherche" depuis un véhicule
2. Remplir le motif (obligatoire)
3. Sélectionner le niveau de priorité (faible, moyen, élevé)
4. **[NOUVEAU]** Cliquer sur "Ajouter des images" pour joindre des photos (optionnel)
5. **[NOUVEAU]** Renseigner le numéro de châssis si connu (optionnel)
6. Soumettre le formulaire

## Fonctionnalités ajoutées

✅ **Upload multiple d'images** pour les avis de recherche (particuliers et véhicules)
✅ **Champ numéro de châssis** pour les avis de recherche de véhicules
✅ **Aperçu visuel** des images sélectionnées avec possibilité de suppression
✅ **Validation** des extensions d'images côté backend
✅ **Compatibilité** web et mobile via ImageUtils
✅ **Correction** du dépassement de la modal (46 pixels)

## Points techniques

### Compatibilité web/mobile
L'utilisation de `ImageUtils` garantit :
- Sur le web : Lecture des images via `readAsBytes()` et `Image.memory()`
- Sur mobile : Utilisation de `Image.file()` avec le chemin local
- Upload universel via `MultipartFile.fromBytes()` ou `MultipartFile.fromPath()`

### Sécurité
- Extensions autorisées : jpg, jpeg, png, gif, webp
- Noms de fichiers uniques pour éviter les conflits
- Stockage hors de la racine web publique (dans `/uploads/`)

### Performance
- Index sur `numero_chassis` pour accélérer les recherches
- Images stockées localement, pas en base64
- Chemins JSON pour une récupération rapide

## Tests recommandés

1. ✅ Vérifier que la modal ne déborde plus (hauteur augmentée)
2. ⚠️ Tester l'upload d'images pour un particulier
3. ⚠️ Tester l'upload d'images pour un véhicule
4. ⚠️ Vérifier que le champ châssis apparaît uniquement pour les véhicules
5. ⚠️ Tester la suppression d'images avant soumission
6. ⚠️ Vérifier que les images sont bien enregistrées dans `/uploads/avis_recherche/`
7. ⚠️ Vérifier que les chemins sont correctement stockés en JSON dans la BDD
8. ⚠️ Tester sur web et mobile

## Migration

**IMPORTANT :** Avant de tester, exécuter la migration de la base de données :

```bash
cd /Users/apple/Documents/dev/flutter/bcr
php api/database/migrate_avis_recherche_images.php
```

Cette migration :
- Ajoute les colonnes `images` et `numero_chassis` à la table `avis_recherche`
- Crée l'index `idx_numero_chassis`
- Est idempotente (peut être exécutée plusieurs fois sans erreur)

## Prochaines étapes possibles

- Afficher les images dans la liste des avis de recherche actifs
- Permettre la modification des avis de recherche (images, numéro châssis)
- Ajouter une galerie d'images dans les détails d'un avis de recherche
- Rechercher par numéro de châssis dans la recherche globale
- Compression automatique des images avant upload
- Limitation du nombre/taille des images
