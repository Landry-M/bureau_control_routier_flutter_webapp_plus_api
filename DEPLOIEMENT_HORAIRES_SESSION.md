# Déploiement - Système de vérification des horaires en session

## Fichiers à déployer sur le serveur de production

### 1. Fichiers PHP créés (backend)

#### a) `/api/check_session_schedule.php` ⚠️ **NOUVEAU - OBLIGATOIRE**
Endpoint pour vérifier les horaires pendant la session.

**Action** : Uploader ce fichier dans `/api/` sur votre serveur

#### b) `/api/config/timezone.php` ⚠️ **NOUVEAU - OBLIGATOIRE**
Configuration du fuseau horaire (UTC+2).

**Action** : Uploader ce fichier dans `/api/config/` sur votre serveur

#### c) `/api/config/database.php` ⚠️ **MODIFIÉ**
Mise à jour pour inclure le timezone.

**Action** : Re-uploader ce fichier dans `/api/config/` sur votre serveur

### 2. Fichiers Flutter modifiés (frontend)

#### a) `/lib/providers/auth_provider.dart` ⚠️ **MODIFIÉ**
Gestion de l'inactivité et vérification des horaires.

#### b) `/lib/services/session_schedule_service.dart` ⚠️ **NOUVEAU**
Service de vérification des horaires.

#### c) `/lib/widgets/schedule_guard.dart` ⚠️ **MODIFIÉ**
Ajout du callback d'inactivité.

#### d) `/lib/widgets/activity_detector.dart` ⚠️ **NOUVEAU**
Détection des interactions utilisateur.

#### e) `/lib/main.dart` ⚠️ **MODIFIÉ**
Intégration de ActivityDetector.

#### f) `/lib/screens/dashboard_screen.dart` ⚠️ **MODIFIÉ**
Restriction du rapport d'activité aux superadmins.

#### g) `/lib/routes.dart` ⚠️ **MODIFIÉ**
Protection de la route /activity-report.

#### h) `/lib/theme.dart` ⚠️ **MODIFIÉ**
Indicateurs de chargement en blanc.

## Étapes de déploiement

### Étape 1 : Déployer les fichiers PHP (URGENT)

**Via FTP/SFTP :**

```bash
# Uploader ces fichiers sur votre serveur :
/api/check_session_schedule.php        → À la racine du dossier /api/
/api/config/timezone.php                → Dans /api/config/
/api/config/database.php                → Dans /api/config/ (remplacer l'existant)
```

**Via ligne de commande (si vous avez accès SSH) :**

```bash
# Depuis votre machine locale
scp api/check_session_schedule.php user@votre-serveur:/path/to/api/
scp api/config/timezone.php user@votre-serveur:/path/to/api/config/
scp api/config/database.php user@votre-serveur:/path/to/api/config/
```

### Étape 2 : Vérifier les permissions

```bash
# Sur le serveur, donner les bonnes permissions
chmod 644 /path/to/api/check_session_schedule.php
chmod 644 /path/to/api/config/timezone.php
chmod 644 /path/to/api/config/database.php
```

### Étape 3 : Tester l'endpoint

**Test 1 : Vérifier que le fichier est accessible**

```bash
curl https://votre-domaine.com/api/check_session_schedule.php?user_id=1
```

**Réponse attendue (si utilisateur autorisé) :**
```json
{
  "success": true,
  "authorized": true,
  "message": "Accès autorisé",
  "current_time": "13:50",
  "current_day": 1
}
```

**Test 2 : Via navigateur**

Ouvrir :
```
https://votre-domaine.com/api/check_session_schedule.php?matricule=police001
```

### Étape 4 : Déployer l'application Flutter

**Rebuild et déployez :**

```bash
# Depuis le répertoire du projet
flutter build web --release

# Uploader le contenu de build/web/ sur votre serveur
```

### Étape 5 : Vérifier le fuseau horaire

**Test PHP sur le serveur :**

Créer un fichier temporaire `/api/test_timezone.php` :

```php
<?php
require_once __DIR__ . '/config/timezone.php';

echo "Fuseau horaire: " . date_default_timezone_get() . "\n";
echo "Heure actuelle: " . date('Y-m-d H:i:s') . "\n";
echo "Heure locale attendue: UTC+2\n";
?>
```

Accéder à : `https://votre-domaine.com/api/test_timezone.php`

**Résultat attendu :**
```
Fuseau horaire: Africa/Johannesburg
Heure actuelle: 2025-10-13 13:50:00
Heure locale attendue: UTC+2
```

## Dépannage

### Erreur : "check_session_schedule.php not found" (404)

**Causes possibles :**
1. Le fichier n'a pas été uploadé
2. Le chemin est incorrect
3. Problème de permissions

**Solutions :**

```bash
# Vérifier que le fichier existe sur le serveur
ls -la /path/to/api/check_session_schedule.php

# Vérifier les permissions
ls -l /path/to/api/check_session_schedule.php
# Devrait afficher : -rw-r--r--

# Si non, corriger :
chmod 644 /path/to/api/check_session_schedule.php
```

### Erreur : "timezone.php not found"

**Solution :**
```bash
# Vérifier que le fichier existe
ls -la /path/to/api/config/timezone.php

# Si non, le créer manuellement sur le serveur
nano /path/to/api/config/timezone.php
```

Contenu :
```php
<?php
date_default_timezone_set('Africa/Johannesburg');
?>
```

### Erreur : "CORS policy"

**Solution :**
Le fichier `check_session_schedule.php` contient déjà les headers CORS :
```php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
```

Si le problème persiste, vérifier le fichier `.htaccess` à la racine de `/api/`.

### Décalage horaire persistent

**Solution :**
1. Vérifier que `timezone.php` est bien chargé
2. Vérifier que le fuseau est correct pour votre région

**Pour l'Afrique :**
- **Cameroun, Congo, etc.** : `Africa/Douala` (UTC+1)
- **Afrique du Sud, Zimbabwe** : `Africa/Johannesburg` (UTC+2)
- **Kenya, Tanzanie** : `Africa/Nairobi` (UTC+3)

Modifier dans `/api/config/timezone.php` selon votre pays.

## Checklist de déploiement

- [ ] ✅ Fichier `check_session_schedule.php` uploadé dans `/api/`
- [ ] ✅ Fichier `timezone.php` uploadé dans `/api/config/`
- [ ] ✅ Fichier `database.php` mis à jour dans `/api/config/`
- [ ] ✅ Permissions vérifiées (644)
- [ ] ✅ Test endpoint réussi (curl ou navigateur)
- [ ] ✅ Fuseau horaire correct (date/heure affichée)
- [ ] ✅ Application Flutter rebuild et déployée
- [ ] ✅ Test de connexion avec horaires restreints
- [ ] ✅ Vérification session expire après 1h inactivité

## Commande de déploiement rapide

Si vous utilisez le script FTP existant, ajoutez ces fichiers :

```bash
# Dans votre script deploy-ftp.sh ou similaire
# Ajouter ces lignes :

put api/check_session_schedule.php
put api/config/timezone.php
put api/config/database.php
```

## Fichiers de test (optionnels)

Ces fichiers peuvent être uploadés temporairement pour les tests :

- `/api/test_user_testes.php` - Test des horaires d'un utilisateur
- `/api/test_login_testes.php` - Test de connexion complète
- `/api/test_timezone.php` - Vérification du fuseau horaire

**⚠️ À supprimer après les tests !**

## Support

Si vous rencontrez des problèmes après le déploiement :

1. **Vérifier les logs du serveur web** (Apache/Nginx)
2. **Vérifier les logs PHP** (`error_log`)
3. **Tester l'endpoint directement** via curl ou navigateur
4. **Vérifier la console du navigateur** pour voir les erreurs réseau

## Résumé

**Fichiers critiques à déployer en priorité :**
1. `/api/check_session_schedule.php` ← **OBLIGATOIRE**
2. `/api/config/timezone.php` ← **OBLIGATOIRE**
3. `/api/config/database.php` ← **OBLIGATOIRE**

Sans ces 3 fichiers, le système de vérification des horaires et d'expiration de session ne fonctionnera pas.
