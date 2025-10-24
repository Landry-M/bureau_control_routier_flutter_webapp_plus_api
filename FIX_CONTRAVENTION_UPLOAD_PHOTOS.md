# Fix Upload Photos Contraventions

## 🔴 Problèmes identifiés

1. **Photos non uploadées** : Les fichiers ne sont pas transférés sur le serveur
2. **Colonne 'photos' vide** : Aucun chemin n'est enregistré dans la base de données
3. **Dossier manquant** : `/api/uploads/contraventions/` peut ne pas exister

## ✅ Corrections apportées

### 1. Backend PHP (`/api/routes/index.php`)

**Problème** : PHP ne recevait pas les fichiers correctement car Flutter envoyait plusieurs fichiers avec le même nom sans `[]`.

**Correction** :
```php
// Fonction helper pour gérer les uploads
$uploadPhoto = function($fileKey) use ($uploadDir, &$uploadedPhotos) {
    if (isset($_FILES[$fileKey])) {
        if (is_array($_FILES[$fileKey]['name'])) {
            // Format tableau (photos[])
            for ($i = 0; $i < count($_FILES[$fileKey]['name']); $i++) {
                if ($_FILES[$fileKey]['error'][$i] === UPLOAD_ERR_OK) {
                    $extension = pathinfo($_FILES[$fileKey]['name'][$i], PATHINFO_EXTENSION);
                    $fileName = 'contrav_' . uniqid() . '_' . time() . '_' . $i . '.' . $extension;
                    $filePath = $uploadDir . $fileName;
                    
                    if (move_uploaded_file($_FILES[$fileKey]['tmp_name'][$i], $filePath)) {
                        $uploadedPhotos[] = 'uploads/contraventions/' . $fileName;
                        error_log("Photo uploaded: " . $fileName);
                    }
                }
            }
        }
    }
};
```

**Changements clés** :
- ✅ Gestion des formats tableau et fichier unique
- ✅ Création automatique du dossier avec permissions `0777`
- ✅ Logging pour debug
- ✅ Chemin relatif sans `/api/` au début : `uploads/contraventions/`
- ✅ Noms de fichiers uniques avec `uniqid()` + timestamp

### 2. Frontend Flutter - Particuliers

**Fichier** : `/lib/widgets/assign_contravention_particulier_modal.dart`

**Problème** : Le nom du champ était `'photos'` au lieu de `'photos[]'`.

**Correction** :
```dart
final multipartFile = http.MultipartFile.fromBytes(
  'photos[]',  // ✅ Ajout de [] pour que PHP reçoive un tableau
  image.bytes!,
  filename: 'contrav_${DateTime.now().millisecondsSinceEpoch}_$i.${image.extension ?? 'jpg'}',
);
```

### 3. Frontend Flutter - Entreprises

**Fichier** : `/lib/widgets/assign_contravention_entreprise_modal.dart`

**Même correction** :
```dart
final multipartFile = http.MultipartFile.fromBytes(
  'photos[]',  // ✅ Ajout de [] pour que PHP reçoive un tableau
  image.bytes!,
  filename: 'contrav_${DateTime.now().millisecondsSinceEpoch}_$i.${image.extension ?? 'jpg'}',
);
```

### 4. Affichage des photos (`contravention_display.php`)

**Corrections multiples** :
- ✅ Utilisation de `$cv['photos']` au lieu de `$cv['images']`
- ✅ Gestion de 3 formats : JSON, virgules, chaîne simple
- ✅ Construction d'URL intelligente
- ✅ Section debug si parsing échoue

**Parsing des photos** :
```php
$images = [];
if (!empty($cv['photos'])) {
    // JSON
    $imagesJson = json_decode($cv['photos'], true);
    if (is_array($imagesJson)) {
        $images = $imagesJson;
    } else {
        // Virgules
        if (strpos($cv['photos'], ',') !== false) {
            $images = explode(',', $cv['photos']);
            $images = array_map('trim', $images);
            $images = array_filter($images);
        } else {
            // Simple
            $images = [trim($cv['photos'])];
        }
    }
}
```

**Construction URL** :
```php
foreach ($images as $image) {
    $imageUrl = trim($image);
    if (!preg_match('/^https?:\/\//', $imageUrl)) {
        $imageUrl = ltrim($imageUrl, '/');
        if (!preg_match('/^api\//', $imageUrl)) {
            if (preg_match('/^uploads\//', $imageUrl)) {
                $imageUrl = 'api/' . $imageUrl;
            }
        }
        $imageUrls[] = $baseUrl . '/' . $imageUrl;
    }
}
```

**Exemple URL générée** :
```
http://localhost/api/uploads/contraventions/contrav_67890abc_1234567890_0.jpg
```

## 🧪 Scripts de test créés

### 1. `test_contravention_upload.php`
Script complet de vérification :
- ✅ Vérification du dossier d'upload et permissions
- ✅ Liste des fichiers existants
- ✅ Structure de la table `contraventions`
- ✅ Dernières contraventions créées avec photos
- ✅ Instructions de test

### 2. `debug_contravention.php?id=XXX`
Diagnostic détaillé d'une contravention :
- 💰 Statut de paiement (valeur, type, condition)
- 📸 Photos (parsing, URLs, aperçu)
- 📋 Données complètes

### 3. `fix_contravention_payed.php`
Correction des anciennes contraventions :
- Convertit '0' → 'non'
- Convertit '1' → 'oui'

## 📋 Checklist de vérification

Avant de tester :
- [ ] Le dossier `/api/uploads/contraventions/` existe et a les bonnes permissions
- [ ] La colonne `photos` existe dans la table `contraventions`
- [ ] Les modifications Flutter sont appliquées (hot reload)
- [ ] Les modifications PHP sont en place

## 🧪 Procédure de test

1. **Vérification préliminaire** :
   ```
   http://localhost/test_contravention_upload.php
   ```

2. **Créer une contravention** :
   - Ouvrir l'app Flutter
   - Créer une contravention (particulier/entreprise)
   - Ajouter 2-3 photos
   - Cocher "Amende payée"
   - Soumettre

3. **Vérifier l'upload** :
   - Actualiser `test_contravention_upload.php`
   - La nouvelle contravention doit apparaître avec des photos ✅
   - Les fichiers doivent être dans `/api/uploads/contraventions/`

4. **Vérifier l'affichage** :
   ```
   http://localhost/contravention_display.php?id=XXX
   ```
   - Les photos doivent s'afficher dans une grille
   - Le statut doit être "✅ Oui" si cochée
   - Cliquer sur une photo doit l'agrandir

5. **Debug si nécessaire** :
   ```
   http://localhost/debug_contravention.php?id=XXX
   ```

## 📊 Format de stockage

### Dans la base de données (colonne `photos`) :

**Format virgules** (actuel) :
```
uploads/contraventions/contrav_abc123_1234567890_0.jpg,uploads/contraventions/contrav_abc123_1234567890_1.jpg
```

**Format JSON** (supporté) :
```json
["uploads/contraventions/contrav_abc123_1234567890_0.jpg","uploads/contraventions/contrav_abc123_1234567890_1.jpg"]
```

### Sur le disque :
```
/api/uploads/contraventions/
├── contrav_67890abc_1234567890_0.jpg
├── contrav_67890abc_1234567890_1.jpg
└── contrav_67890abc_1234567890_2.jpg
```

## 🐛 Dépannage

### Les photos ne s'uploadent pas

**Vérifier** :
1. Permissions du dossier : `chmod 777 api/uploads/contraventions/`
2. Logs PHP : `tail -f /var/log/php_errors.log`
3. Nom du champ dans Flutter : doit être `'photos[]'`
4. Backend reçoit les fichiers : voir logs "FILES received"

### Les photos ne s'affichent pas

**Vérifier** :
1. Colonne `photos` contient des données
2. Chemin est relatif : `uploads/contraventions/...` (pas `/api/...`)
3. Fichiers existent physiquement sur le disque
4. URLs générées dans la console du navigateur (F12)

### Erreur "Column 'photos' not found"

**Solution** :
```sql
ALTER TABLE contraventions ADD COLUMN photos TEXT NULL;
```

## 📝 Notes importantes

1. **Format du nom de champ** : `photos[]` en Flutter → PHP reçoit un tableau
2. **Format du chemin** : `uploads/contraventions/file.jpg` (sans `/api/`)
3. **URL finale** : `http://localhost/api/uploads/contraventions/file.jpg`
4. **Permissions** : Dossier doit avoir `0777` pour écriture
5. **Logs** : Activés pour debug avec `error_log()`

## ✅ Résultat attendu

Après ces corrections :
- ✅ Photos uploadées dans `/api/uploads/contraventions/`
- ✅ Chemins enregistrés dans la colonne `photos`
- ✅ Photos affichées dans `contravention_display.php`
- ✅ Statut "Amende payée" correct
- ✅ Modal d'agrandissement fonctionnel
- ✅ Export PDF inclut les photos
