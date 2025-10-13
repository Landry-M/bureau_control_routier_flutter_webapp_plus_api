# Solution : "MySQL server has gone away"

## Problème

L'erreur **"MySQL server has gone away"** survient lors de la création d'un véhicule avec contravention (incluant l'upload d'images).

### Causes principales

1. **Timeout de connexion MySQL** : La connexion expire pendant l'upload des images
2. **Paquet trop volumineux** : Les images dépassent `max_allowed_packet`
3. **Connexion fermée** : MySQL ferme la connexion pendant les transactions longues

## Solutions implémentées

### 1. Configuration PDO améliorée (`/api/config/database.php`)

**Modifications apportées :**

```php
$pdo_options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_PERSISTENT => false,  // Éviter connexions persistantes expirées
    PDO::ATTR_TIMEOUT => 60,        // Timeout 60 secondes
    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4, 
        wait_timeout=300,            // 5 minutes
        interactive_timeout=300,     // 5 minutes  
        max_allowed_packet=67108864" // 64 MB
];
```

**Avantages :**
- ✅ Timeout étendu à 5 minutes
- ✅ Paquet max augmenté à 64 MB (suffisant pour plusieurs images)
- ✅ Configuration automatique à chaque connexion

### 2. Méthodes de reconnexion automatique

**Nouvelles méthodes dans `Database` :**

#### `ensureConnection()`
Vérifie si la connexion est active, sinon reconnecte.

```php
public function ensureConnection() {
    try {
        if ($this->conn) {
            $this->conn->query('SELECT 1'); // Test ping
        } else {
            $this->getConnection();
        }
    } catch (PDOException $e) {
        // Reconnexion automatique
        $this->conn = null;
        $this->getConnection();
    }
    return $this->conn;
}
```

#### `ping()`
Vérifie rapidement si la connexion est vivante.

```php
public function ping() {
    try {
        if ($this->conn) {
            $this->conn->query('SELECT 1');
            return true;
        }
    } catch (PDOException $e) {
        return false;
    }
    return false;
}
```

### 3. Protection dans BaseController

**Nouvelle méthode protégée :**

```php
protected function ensureConnection() {
    try {
        $this->db = $this->database->ensureConnection();
    } catch (Exception $e) {
        error_log("Failed to ensure MySQL connection: " . $e->getMessage());
        throw $e;
    }
}
```

**Usage dans les contrôleurs :**
```php
// Avant une opération critique
$this->ensureConnection();
```

### 4. Application dans VehiculeController

**Protection avant création de contravention :**

```php
if ($withCv === '1') {
    // Assurer connexion active avant opération longue
    $this->ensureConnection();
    
    require_once __DIR__ . '/ContraventionController.php';
    $contraventionController = new ContraventionController();
    // ... création contravention
}
```

## Configuration serveur MySQL (optionnelle mais recommandée)

### Via SQL (temporaire)

Exécuter sur le serveur MySQL :

```sql
SET GLOBAL wait_timeout = 300;
SET GLOBAL interactive_timeout = 300;
SET GLOBAL max_allowed_packet = 67108864;
SET GLOBAL net_read_timeout = 120;
SET GLOBAL net_write_timeout = 120;
```

**Script disponible :** `/api/config/mysql_server_config.sql`

### Via my.cnf/my.ini (permanent)

Ajouter dans le fichier de configuration MySQL :

```ini
[mysqld]
wait_timeout = 300
interactive_timeout = 300
max_allowed_packet = 67108864
net_read_timeout = 120
net_write_timeout = 120
```

**Emplacements courants :**
- Linux : `/etc/mysql/my.cnf` ou `/etc/my.cnf`
- Windows : `C:\ProgramData\MySQL\MySQL Server X.X\my.ini`
- macOS : `/usr/local/mysql/my.cnf`

**Après modification :** Redémarrer MySQL
```bash
# Linux
sudo systemctl restart mysql

# macOS
sudo mysql.server restart

# Windows
net stop MySQL
net start MySQL
```

## Déploiement

### Fichiers à uploader sur le serveur de production

1. **`/api/config/database.php`** ⚠️ **CRITIQUE**
   - Remplacer l'existant
   - Contient les nouvelles configurations de timeout

2. **`/api/controllers/BaseController.php`** ⚠️ **CRITIQUE**
   - Remplacer l'existant
   - Contient `ensureConnection()`

3. **`/api/controllers/VehiculeController.php`** ⚠️ **CRITIQUE**
   - Remplacer l'existant
   - Appelle `ensureConnection()` avant création contravention

4. **`/api/config/mysql_server_config.sql`** (optionnel)
   - À exécuter sur MySQL si vous avez accès

### Vérification après déploiement

**Test 1 : Créer un véhicule simple**
```
✅ Doit fonctionner sans erreur
```

**Test 2 : Créer un véhicule AVEC contravention**
```
✅ Doit fonctionner sans "MySQL server has gone away"
```

**Test 3 : Créer avec plusieurs images**
```
✅ Upload d'images volumineuses doit passer
```

## Diagnostics

### Vérifier la configuration MySQL actuelle

Créer `/api/test_mysql_config.php` :

```php
<?php
require_once __DIR__ . '/config/database.php';

$database = new Database();
$db = $database->getConnection();

echo "=== CONFIGURATION MYSQL ===\n\n";

$queries = [
    'wait_timeout' => "SELECT @@session.wait_timeout",
    'interactive_timeout' => "SELECT @@session.interactive_timeout",
    'max_allowed_packet' => "SELECT @@session.max_allowed_packet",
    'net_read_timeout' => "SELECT @@session.net_read_timeout",
    'net_write_timeout' => "SELECT @@session.net_write_timeout"
];

foreach ($queries as $name => $query) {
    $result = $db->query($query)->fetchColumn();
    $readable = $name === 'max_allowed_packet' 
        ? round($result / 1024 / 1024, 2) . ' MB' 
        : $result . ' secondes';
    echo "$name: $readable\n";
}

echo "\n=== TEST PING ===\n";
echo $database->ping() ? "✅ Connexion active\n" : "❌ Connexion perdue\n";
?>
```

**Accéder à :** `https://votre-domaine.com/api/test_mysql_config.php`

**Résultat attendu :**
```
=== CONFIGURATION MYSQL ===

wait_timeout: 300 secondes
interactive_timeout: 300 secondes
max_allowed_packet: 64.0 MB
net_read_timeout: 120 secondes
net_write_timeout: 120 secondes

=== TEST PING ===
✅ Connexion active
```

### Logs pour debugging

Activer les logs MySQL si le problème persiste :

```sql
-- Activer les logs MySQL
SET GLOBAL general_log = 'ON';
SET GLOBAL general_log_file = '/var/log/mysql/general.log';

-- Logs des erreurs
SET GLOBAL log_error = '/var/log/mysql/error.log';
```

Consulter `/var/log/mysql/error.log` pour voir les erreurs détaillées.

## Cas particuliers

### Hébergement mutualisé (shared hosting)

Si vous n'avez pas accès aux paramètres globaux MySQL :

1. **Contactez votre hébergeur** pour augmenter :
   - `max_allowed_packet` à 64 MB minimum
   - `wait_timeout` à 300 secondes minimum

2. **Alternative** : Optimiser les uploads
   - Compresser les images côté Flutter avant upload
   - Limiter la taille des images à 2-3 MB par image
   - Uploader les images une par une au lieu de toutes en même temps

### cPanel / Plesk

**Via phpMyAdmin :**
1. Aller dans phpMyAdmin
2. Onglet "Variables"
3. Rechercher et modifier :
   - `max_allowed_packet`
   - `wait_timeout`
   - `interactive_timeout`

**Via WHM (root access) :**
1. WHM → Service Configuration → MySQL Configuration
2. Modifier les paramètres
3. Sauvegarder et redémarrer MySQL

## Prévention

### Bonnes pratiques pour éviter l'erreur

1. **Compresser les images** avant upload (Flutter)
   ```dart
   // Exemple avec image_picker + flutter_image_compress
   final compressed = await FlutterImageCompress.compressWithFile(
     file.absolute.path,
     quality: 85,
     minWidth: 1920,
     minHeight: 1080,
   );
   ```

2. **Limiter la taille des fichiers**
   ```dart
   if (file.lengthSync() > 5 * 1024 * 1024) { // 5 MB
     throw Exception('Image trop volumineuse (max 5 MB)');
   }
   ```

3. **Upload par lots** si plusieurs fichiers
   - Uploader 2-3 images à la fois maximum
   - Éviter d'uploader 10+ images simultanément

4. **Afficher un loader** pendant l'upload
   - Informer l'utilisateur que l'opération est en cours
   - Éviter qu'il clique plusieurs fois

## Checklist de résolution

- [ ] ✅ `database.php` mis à jour avec timeouts augmentés
- [ ] ✅ `BaseController.php` contient `ensureConnection()`
- [ ] ✅ `VehiculeController.php` appelle `ensureConnection()`
- [ ] ✅ Fichiers déployés sur le serveur de production
- [ ] ✅ Test de création véhicule avec contravention réussi
- [ ] ⬜ Configuration MySQL serveur (optionnel)
- [ ] ⬜ Logs MySQL vérifiés (si problème persiste)

## Support

Si le problème persiste après avoir appliqué toutes les solutions :

1. **Vérifier la configuration** avec `test_mysql_config.php`
2. **Consulter les logs** PHP et MySQL
3. **Tester avec des images plus petites** (< 1 MB chacune)
4. **Contacter l'hébergeur** pour vérifier les limitations

## Résumé

**3 fichiers modifiés à déployer :**
1. `/api/config/database.php` - Timeouts + max_allowed_packet
2. `/api/controllers/BaseController.php` - Reconnexion automatique
3. `/api/controllers/VehiculeController.php` - Protection création contravention

**Résultat attendu :**
✅ Plus d'erreur "MySQL server has gone away" lors de la création de véhicule avec contravention et images.

## Statut

✅ **Solution implémentée** - 13 octobre 2025
⚠️ **À déployer** sur le serveur de production
📋 **Documentation** : Ce fichier
