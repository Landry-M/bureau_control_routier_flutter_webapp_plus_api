# Fix Upload Multiple Photos - Une seule photo uploadée

## 🔴 Problème

Quand l'utilisateur sélectionnait 2 photos, **seulement 1 photo était uploadée** sur le serveur.

## 🔍 Cause

Tous les fichiers étaient envoyés avec le **même nom de champ** `'photos[]'`. Dans certaines configurations PHP/serveur, cela peut causer des problèmes où seul le dernier fichier est conservé.

### Ancien code Flutter :
```dart
for (int i = 0; i < _selectedImages.length; i++) {
  final multipartFile = http.MultipartFile.fromBytes(
    'photos[]',  // ❌ Tous les fichiers ont le même nom de champ
    image.bytes!,
    filename: 'contrav_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
  );
  imageFiles.add(multipartFile);
}
```

## ✅ Solution

Chaque fichier a maintenant son **propre nom de champ unique** : `photo_0`, `photo_1`, `photo_2`, etc.

### Nouveau code Flutter :
```dart
for (int i = 0; i < _selectedImages.length; i++) {
  final multipartFile = http.MultipartFile.fromBytes(
    'photo_$i',  // ✅ Chaque fichier a un nom unique
    image.bytes!,
    filename: 'contrav_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
  );
  imageFiles.add(multipartFile);
}
```

### Backend PHP mis à jour :
Au lieu de chercher spécifiquement `'photos'` ou `'photos[]'`, le backend **boucle maintenant sur TOUS les fichiers** dans `$_FILES` qui contiennent le mot "photo" dans leur clé :

```php
foreach ($_FILES as $fileKey => $fileData) {
    if (stripos($fileKey, 'photo') !== false) {
        // Traiter le fichier (format tableau ou unique)
        // ...
    }
}
```

Cela supporte désormais :
- ✅ `photo_0`, `photo_1`, `photo_2`, etc. (nouveau format)
- ✅ `photos[]` (ancien format tableau)
- ✅ `photos` (format simple)
- ✅ Tout autre nom contenant "photo"

## 📝 Fichiers modifiés

### Frontend (Flutter) :
1. `/lib/widgets/assign_contravention_particulier_modal.dart`
2. `/lib/widgets/assign_contravention_entreprise_modal.dart`

### Backend (PHP) :
1. `/api/routes/index.php` - Endpoint `/contravention/create`

## 🧪 Scripts de test

### 1. `test_upload_receiver.php`
Script de diagnostic complet qui affiche :
- Toutes les données POST reçues
- Tous les fichiers reçus avec détails (nom, taille, erreur)
- Headers HTTP
- Configuration PHP upload
- Test d'upload simulation
- Formulaire de test HTML

**Usage** :
```
http://localhost/test_upload_receiver.php
```

Vous pouvez tester depuis :
- Le formulaire HTML intégré
- L'application Flutter

### 2. `test_contravention_upload.php`
Vérification complète du système :
- Dossier d'upload et permissions
- Structure de la table
- Dernières contraventions
- Instructions

### 3. `debug_contravention.php?id=XXX`
Diagnostic d'une contravention spécifique

## 🎯 Test étape par étape

### 1. Vérification préliminaire

Vérifier que tout est en place :
```
http://localhost/test_contravention_upload.php
```

Vérifier que :
- ✅ Le dossier `/api/uploads/contraventions/` existe
- ✅ Les permissions sont correctes (0777)
- ✅ La colonne `photos` existe dans la table

### 2. Test depuis Flutter

1. **Redémarrer l'application Flutter** (hot reload ne suffit pas pour les changements de logique d'upload)
   ```bash
   flutter run
   ```

2. **Créer une contravention** :
   - Ouvrir l'application
   - Créer une contravention (particulier ou entreprise)
   - **Sélectionner 2 ou 3 photos** 📸📸📸
   - Cocher "Amende payée" si vous voulez
   - Soumettre

3. **Vérifier l'upload** :
   - Ouvrir `test_contravention_upload.php`
   - La nouvelle contravention doit apparaître
   - Elle doit montrer **2 ou 3 photo(s)** ✅
   - Chaque photo doit être listée

4. **Vérifier l'affichage** :
   ```
   http://localhost/contravention_display.php?id=XXX
   ```
   - Toutes les photos doivent s'afficher dans la grille
   - Cliquer sur une photo pour l'agrandir

### 3. Test depuis le formulaire HTML

Si vous voulez tester sans Flutter :

1. Ouvrir `test_upload_receiver.php`
2. Utiliser le formulaire de test
3. Sélectionner plusieurs photos (2-3)
4. Cliquer "Envoyer"
5. La page doit afficher tous les fichiers reçus

## 🔍 Vérification des logs

Pour voir les logs en temps réel pendant l'upload :

**Mac/Linux** :
```bash
tail -f /var/log/php_errors.log
```

**Windows** :
Consulter les logs Apache dans `C:\xampp\apache\logs\error.log`

### Logs attendus :

Quand vous uploadez 2 photos, vous devriez voir :
```
FILES received: Array
(
    [photo_0] => Array
        (
            [name] => contrav_1234567890_0.jpg
            [type] => image/jpeg
            [tmp_name] => /tmp/php123abc
            [error] => 0
            [size] => 54321
        )
    [photo_1] => Array
        (
            [name] => contrav_1234567890_1.jpg
            [type] => image/jpeg
            [tmp_name] => /tmp/php456def
            [error] => 0
            [size] => 67890
        )
)
Photo uploaded (single): contrav_abc123_1234567890.jpg from key: photo_0
Photo uploaded (single): contrav_abc123_1234567890.jpg from key: photo_1
Total photos uploaded: 2
```

## 🐛 Dépannage

### Toujours une seule photo uploadée

**Vérifier** :
1. ✅ Hot reload fait ? Non → **Redémarrer l'app** (`flutter run`)
2. ✅ Logs PHP montrent 2 clés (`photo_0`, `photo_1`) ?
3. ✅ Erreurs dans les logs ?

**Si les logs montrent `photos[]` au lieu de `photo_0`, `photo_1`** :
→ Le code Flutter n'a pas été rechargé. Redémarrer complètement l'app.

### Aucune photo uploadée

**Vérifier** :
1. Permissions dossier : `chmod 777 api/uploads/contraventions/`
2. Taille des fichiers : `upload_max_filesize` et `post_max_size` dans php.ini
3. Logs PHP pour voir les erreurs

### Photos non visibles sur le display

**Vérifier** :
1. La colonne `photos` contient bien des chemins (vérifier avec `debug_contravention.php`)
2. Les fichiers existent physiquement dans `/api/uploads/contraventions/`
3. Les URLs générées dans la console du navigateur (F12)

## 📊 Exemple de données

### Dans `$_FILES` (PHP) :
```php
Array
(
    [photo_0] => Array
    (
        [name] => contrav_1234567890_0.jpg
        [type] => image/jpeg
        [tmp_name] => /tmp/php123abc
        [error] => 0
        [size] => 54321
    )
    [photo_1] => Array
    (
        [name] => contrav_1234567890_1.jpg
        [type] => image/jpeg
        [tmp_name] => /tmp/php456def
        [error] => 0
        [size] => 67890
    )
)
```

### Dans la base de données (colonne `photos`) :
```
uploads/contraventions/contrav_abc123_1234567890.jpg,uploads/contraventions/contrav_def456_1234567890.jpg
```

### Sur le disque :
```
/api/uploads/contraventions/
├── contrav_abc123_1234567890.jpg  (photo 0)
├── contrav_def456_1234567891.jpg  (photo 1)
└── contrav_ghi789_1234567892.jpg  (photo 2)
```

## ✅ Résultat attendu

Après ces corrections :
- ✅ **Toutes les photos** sont uploadées (2, 3, 4+)
- ✅ Chaque photo a un fichier physique unique sur le serveur
- ✅ Tous les chemins sont enregistrés dans la colonne `photos`
- ✅ Toutes les photos s'affichent dans `contravention_display.php`
- ✅ Les logs montrent clairement chaque upload

## 📝 Notes techniques

### Pourquoi `photo_$i` au lieu de `photos[]` ?

Avec `photos[]`, tous les fichiers ont techniquement le même nom de champ. Dans certains cas :
- Le serveur peut ne garder que le dernier
- PHP peut avoir des problèmes selon la configuration
- Debugging devient plus difficile

Avec `photo_0`, `photo_1`, etc. :
- ✅ Chaque fichier a une identité unique
- ✅ Plus facile à debugger
- ✅ Plus compatible avec différentes configurations serveur
- ✅ Le backend peut traiter n'importe quel nombre de fichiers

### Compatibilité

Cette solution est compatible avec :
- ✅ Toutes les versions de PHP (7.x, 8.x)
- ✅ Tous les serveurs web (Apache, Nginx)
- ✅ Toutes les plateformes Flutter (Web, Android, iOS, Desktop)
