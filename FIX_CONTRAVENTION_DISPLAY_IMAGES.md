# Fix Affichage des Photos - Contravention Display

## 🔴 Problème résolu

Les images étaient correctement uploadées et enregistrées dans la base de données, mais ne s'affichaient pas sur la page `contravention_display.php`.

## 🔍 Cause

La logique de construction d'URL des images dans `contravention_display.php` était trop complexe et ne suivait pas le même pattern simplifié que `avis_recherche_display.php`.

### Ancien code (complexe et fragile) :
```php
// Nettoyer le chemin
$imageUrl = ltrim($imageUrl, '/');

// Si le chemin ne commence pas par 'api/', l'ajouter
if (!preg_match('/^api\//', $imageUrl)) {
    // Si ça commence par 'uploads/', ajouter 'api/' avant
    if (preg_match('/^uploads\//', $imageUrl)) {
        $imageUrl = 'api/' . $imageUrl;
    }
    // Sinon, supposer que c'est déjà le bon chemin relatif
}

// Construire l'URL complète
$imageUrls[] = $baseUrl . '/' . $imageUrl;
```

Cette logique avait trop de conditions et pouvait échouer dans certains cas.

## ✅ Solution appliquée

### Simplification de la construction d'URL

Alignement avec le pattern utilisé dans `avis_recherche_display.php` :

```php
// Construire les URLs complètes des images (simplifié)
$baseUrl = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'];
$imageUrls = [];
foreach ($images as $image) {
    $imageUrl = trim($image);
    if (empty($imageUrl)) continue;
    
    // Si c'est déjà une URL complète, l'utiliser telle quelle
    if (preg_match('/^https?:\/\//', $imageUrl)) {
        $imageUrls[] = $imageUrl;
        continue;
    }
    
    // Nettoyer le chemin - enlever le slash initial s'il existe
    $imageUrl = ltrim($imageUrl, '/');
    
    // Reconstruire le chemin complet
    // Le chemin sauvegardé est du type: uploads/contraventions/file.jpg
    // On veut obtenir: http://localhost/api/uploads/contraventions/file.jpg
    $imageUrls[] = $baseUrl . '/api/' . $imageUrl;
}
```

### Amélioration du message d'erreur

Ajout de logging dans la console et affichage de l'URL problématique :

```php
<img 
    src="<?php echo htmlspecialchars($imageUrl); ?>" 
    onerror="console.error('Erreur chargement image:', '<?php echo htmlspecialchars($imageUrl, ENT_QUOTES); ?>'); 
             this.parentElement.innerHTML='<div>❌ Image non disponible<br><small><?php echo substr($imageUrl, 0, 50); ?>...</small></div>';">
```

## 📊 Flux de données

### 1. Upload (Backend PHP) :
```php
// Dans /api/routes/index.php
$uploadedPhotos[] = 'uploads/contraventions/' . $fileName;
// Exemple: uploads/contraventions/contrav_abc123_1234567890.jpg
```

### 2. Stockage en base de données :
```
uploads/contraventions/contrav_abc123_1234567890.jpg,uploads/contraventions/contrav_def456_1234567890.jpg
```
Format : Chaîne séparée par des virgules

### 3. Affichage (contravention_display.php) :
```php
// Parse la chaîne
$images = explode(',', $cv['photos']);

// Construit l'URL
// Input:  uploads/contraventions/contrav_abc123.jpg
// Output: http://localhost/api/uploads/contraventions/contrav_abc123.jpg
```

## 🛠️ Fichiers modifiés

### 1. `/contravention_display.php` (lignes ~163-182)
- Simplification de la logique de construction d'URL
- Suppression des conditions complexes
- Pattern unifié avec les avis de recherche

### 2. `/api/debug_contravention_photos.php` (nouveau)
Script de diagnostic pour vérifier :
- ✅ Les 5 dernières contraventions
- ✅ Le contenu brut de la colonne `photos`
- ✅ Le format détecté (JSON, virgules, simple)
- ✅ Les URLs construites
- ✅ L'existence physique des fichiers
- ✅ Prévisualisation des images

**Utilisation** :
```
http://localhost/api/debug_contravention_photos.php
```

## 🧪 Test de la solution

### Étape 1 : Vérifier les données
Ouvrir : `http://localhost/api/debug_contravention_photos.php`

Vérifier :
- ✅ La colonne `photos` contient des chemins
- ✅ Les fichiers existent physiquement
- ✅ Les URLs construites sont correctes
- ✅ Les images se chargent dans le debug

### Étape 2 : Tester l'affichage
Créer une nouvelle contravention avec 2-3 photos, puis :
1. Ouvrir la page de prévisualisation
2. Les photos doivent s'afficher dans la grille
3. Cliquer sur une photo pour l'agrandir
4. Vérifier dans la console (F12) qu'il n'y a pas d'erreurs

### Étape 3 : Vérifier les URLs
Dans la console du navigateur (F12) :
- Aucune erreur 404 sur les images
- Les URLs sont au format : `http://localhost/api/uploads/contraventions/contrav_xxx.jpg`

## 🔍 Dépannage

### Images toujours pas visibles ?

**1. Vérifier que les fichiers existent**
```bash
ls -la api/uploads/contraventions/
```

**2. Vérifier les permissions**
```bash
chmod 777 api/uploads/contraventions/
```

**3. Utiliser le script de debug**
```
http://localhost/api/debug_contravention_photos.php
```

**4. Vérifier dans la console du navigateur (F12)**
- Onglet "Console" : erreurs de chargement ?
- Onglet "Network" : statut HTTP des images ?

### Erreur 404 sur les images ?

Vérifier que l'URL générée est correcte :
- ✅ Format attendu : `http://localhost/api/uploads/contraventions/file.jpg`
- ❌ Format incorrect : `http://localhost/uploads/contraventions/file.jpg` (manque `/api/`)
- ❌ Format incorrect : `http://localhost/api/api/uploads/contraventions/file.jpg` (double `/api/`)

### Les chemins en base de données sont incorrects ?

Si les chemins stockés ne sont pas au format `uploads/contraventions/file.jpg`, vérifier dans `/api/routes/index.php` (ligne ~2186) :
```php
$uploadedPhotos[] = 'uploads/contraventions/' . $fileName;
```

## 📝 Cohérence avec les avis de recherche

| Aspect | Avis de recherche | Contraventions |
|--------|------------------|----------------|
| **Fichier d'affichage** | `avis_recherche_display.php` | `contravention_display.php` |
| **Construction d'URL** | ✅ Simple | ✅ Simple (après fix) |
| **Pattern** | `$baseUrl . '/api/' . $imageUrl` | `$baseUrl . '/api/' . $imageUrl` |
| **Gestion d'erreur** | ✅ Console + affichage URL | ✅ Console + affichage URL |
| **Script de debug** | `check_avis_images.php` | `debug_contravention_photos.php` |

Les deux systèmes utilisent maintenant **le même pattern** pour la construction d'URL.

## ✅ Résultat attendu

Après ce fix :
- ✅ **Toutes les photos** s'affichent sur `contravention_display.php`
- ✅ La grille d'images est visible
- ✅ Les images peuvent être agrandies en cliquant dessus
- ✅ Pas d'erreur 404 dans la console
- ✅ L'export PDF inclut les images
- ✅ Cohérence avec les avis de recherche

## 🎯 Pattern standard pour affichage d'images

Pour tout futur fichier d'affichage nécessitant des images :

```php
// 1. Parser les chemins depuis la DB
$images = [];
if (!empty($data['photos'])) {
    // JSON
    $imagesJson = json_decode($data['photos'], true);
    if (is_array($imagesJson)) {
        $images = $imagesJson;
    }
    // Virgules
    elseif (strpos($data['photos'], ',') !== false) {
        $images = explode(',', $data['photos']);
        $images = array_map('trim', $images);
        $images = array_filter($images);
    }
    // Simple
    else {
        $images = [trim($data['photos'])];
    }
}

// 2. Construire les URLs (pattern standard)
$baseUrl = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'];
$imageUrls = [];
foreach ($images as $image) {
    $imageUrl = trim($image);
    if (empty($imageUrl)) continue;
    
    if (preg_match('/^https?:\/\//', $imageUrl)) {
        $imageUrls[] = $imageUrl;
        continue;
    }
    
    $imageUrl = ltrim($imageUrl, '/');
    $imageUrls[] = $baseUrl . '/api/' . $imageUrl;
}

// 3. Afficher avec gestion d'erreur
<?php foreach ($imageUrls as $index => $imageUrl): ?>
    <img 
        src="<?php echo htmlspecialchars($imageUrl); ?>" 
        alt="Photo <?php echo ($index + 1); ?>"
        onerror="console.error('Erreur:', '<?php echo htmlspecialchars($imageUrl, ENT_QUOTES); ?>'); 
                 this.style.display='none';">
<?php endforeach; ?>
```

Ce pattern est maintenant **standard** dans toute l'application pour garantir la cohérence.
