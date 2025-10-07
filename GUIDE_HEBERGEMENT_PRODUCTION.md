# 🚀 Guide d'Hébergement Production - Application BCR

## 📋 Table des Matières
1. [Architecture Générale](#architecture-générale)
2. [Hiérarchie des Dossiers](#hiérarchie-des-dossiers)
3. [Configuration Serveur](#configuration-serveur)
4. [Base de Données](#base-de-données)
5. [Gestion des Images](#gestion-des-images)
6. [Configuration Domaine](#configuration-domaine)
7. [SSL et Sécurité](#ssl-et-sécurité)
8. [Déploiement](#déploiement)
9. [Monitoring](#monitoring)

---

## 🏗️ Architecture Générale

### Stack Technologique
- **Frontend** : Flutter Web (compilé en JavaScript)
- **Backend** : PHP 8.1+ avec Apache/Nginx
- **Base de données** : MySQL 8.0+
- **Serveur web** : Apache 2.4+ ou Nginx 1.18+
- **SSL** : Let's Encrypt (gratuit) ou certificat commercial

### Schéma d'Architecture
```
Internet
    ↓
[Reverse Proxy/Load Balancer]
    ↓
[Serveur Web - Apache/Nginx]
    ↓
┌─────────────────┬─────────────────┐
│   Flutter Web   │   API PHP       │
│   (Frontend)    │   (Backend)     │
└─────────────────┴─────────────────┘
    ↓
[Base de Données MySQL]
    ↓
[Stockage Fichiers/Images]
```

---

## 📁 Hiérarchie des Dossiers

### Structure Serveur Production
```
/var/www/bcr-app/
├── public/                          # Document root public
│   ├── index.html                   # Flutter Web compilé
│   ├── main.dart.js                 # Code Flutter compilé
│   ├── flutter.js
│   ├── favicon.png
│   ├── manifest.json
│   ├── assets/                      # Assets Flutter
│   │   ├── AssetManifest.json
│   │   ├── FontManifest.json
│   │   └── fonts/
│   └── api/                         # API PHP
│       ├── routes/
│       │   └── index.php            # Point d'entrée API
│       ├── controllers/             # Contrôleurs métier
│       │   ├── AccidentController.php
│       │   ├── VehiculeController.php
│       │   ├── ParticulierController.php
│       │   └── ...
│       ├── config/
│       │   ├── database.php         # Configuration BDD
│       │   └── cors.php             # Configuration CORS
│       └── uploads/                 # Fichiers uploadés
│           ├── accidents/
│           ├── contraventions/
│           ├── particuliers/
│           └── entreprises/
├── private/                         # Fichiers privés (hors document root)
│   ├── logs/                        # Logs application
│   ├── backups/                     # Sauvegardes BDD
│   ├── config/                      # Configurations sensibles
│   │   ├── .env                     # Variables d'environnement
│   │   └── database.conf
│   └── ssl/                         # Certificats SSL
└── scripts/                         # Scripts maintenance
    ├── backup.sh
    ├── deploy.sh
    └── update.sh
```

---

## ⚙️ Configuration Serveur

### Apache Configuration
```apache
# /etc/apache2/sites-available/controls-app.conf - Application Flutter
<VirtualHost *:80>
    ServerName controls.heaventech.net
    DocumentRoot /var/www/controls-app/public
    
    # Redirection HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

<VirtualHost *:443>
    ServerName controls.heaventech.net
    DocumentRoot /var/www/controls-app/public
    
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/controls.heaventech.net/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/controls.heaventech.net/privkey.pem
    
    # Flutter Web - Servir index.html pour toutes les routes
    <Directory "/var/www/controls-app/public">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        
        # Fallback pour Flutter Router
        FallbackResource /index.html
    </Directory>
    
    # Headers sécurité
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Cache statique
    <FilesMatch "\.(css|js|png|jpg|jpeg|gif|ico|svg)$">
        ExpiresActive On
        ExpiresDefault "access plus 1 month"
    </FilesMatch>
    
    # Logs
    ErrorLog /var/www/controls-app/logs/error.log
    CustomLog /var/www/controls-app/logs/access.log combined
</VirtualHost>

# /etc/apache2/sites-available/bcr-api.conf - API PHP
<VirtualHost *:80>
    ServerName api.bcr.heaventech.net
    DocumentRoot /var/www/bcr-api/public
    
    # Redirection HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

<VirtualHost *:443>
    ServerName api.bcr.heaventech.net
    DocumentRoot /var/www/bcr-api/public
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/api.bcr.heaventech.net/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/api.bcr.heaventech.net/privkey.pem
    
    # API PHP
    <Directory "/var/www/bcr-api/public/api">
        Options -Indexes
        AllowOverride All
        Require all granted
    </Directory>
    
    # Protection uploads - seulement images
    <Directory "/var/www/bcr-api/public/uploads">
        Options -Indexes -ExecCGI
        AllowOverride None
        <FilesMatch "\.(jpg|jpeg|png|gif|pdf)$">
            Require all granted
        </FilesMatch>
        <FilesMatch "\.php$">
            Require all denied
        </FilesMatch>
    </Directory>
    
    # CORS sécurisé pour controls et control.heaventech.net
    SetEnvIf Origin "^https://controls\.heaventech\.net$" CORS_ORIGIN=$0
    SetEnvIf Origin "^https://control\.heaventech\.net$" CORS_ORIGIN=$0
    Header always set Access-Control-Allow-Origin "%{CORS_ORIGIN}e" env=CORS_ORIGIN
    Header always set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
    Header always set Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With"
    Header always set Access-Control-Allow-Credentials "true"
    
    # Headers sécurité
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Compression
    LoadModule deflate_module modules/mod_deflate.so
    <Location />
        SetOutputFilter DEFLATE
        SetEnvIfNoCase Request_URI \
            \.(?:gif|jpe?g|png)$ no-gzip dont-vary
        SetEnvIfNoCase Request_URI \
            \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
    </Location>
    
    # Cache statique
    <FilesMatch "\.(css|js|png|jpg|jpeg|gif|ico|svg)$">
        ExpiresActive On
        ExpiresDefault "access plus 1 month"
    </FilesMatch>
    
    # Logs
    ErrorLog /var/www/bcr-api/logs/error.log
    CustomLog /var/www/bcr-api/logs/access.log combined
</VirtualHost>
```

### Nginx Configuration (Alternative)
```nginx
# /etc/nginx/sites-available/bcr-app
server {
    listen 80;
    server_name api.bcr.heaventech.net bcr.heaventech.net www.bcr.heaventech.net;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.bcr.heaventech.net bcr.heaventech.net www.bcr.heaventech.net;
    
    root /var/www/bcr-app/public;
    index index.html;
    
    # SSL
    ssl_certificate /etc/letsencrypt/live/api.bcr.heaventech.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.bcr.heaventech.net/privkey.pem;
    
    # Flutter Web - SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API PHP
    location /api/ {
        try_files $uri $uri/ /api/routes/index.php?$query_string;
        
        location ~ \.php$ {
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
    
    # Uploads sécurisés
    location /api/uploads/ {
        location ~* \.(jpg|jpeg|png|gif|pdf)$ {
            expires 1M;
            add_header Cache-Control "public, immutable";
        }
        location ~ \.php$ {
            deny all;
        }
    }
    
    # Sécurité
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    
    # Logs
    access_log /var/www/bcr-app/private/logs/access.log;
    error_log /var/www/bcr-app/private/logs/error.log;
}
```

---

## 🗄️ Base de Données

### Configuration MySQL Production
```sql
-- /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
# Sécurité
bind-address = 127.0.0.1
skip-networking = false
skip-name-resolve

# Performance
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
query_cache_size = 64M
max_connections = 200

# Logs
general_log = 1
general_log_file = /var/log/mysql/general.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Charset
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

### Script de Sauvegarde
```bash
#!/bin/bash
# /var/www/bcr-app/scripts/backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/www/bcr-app/private/backups"
DB_NAME="bcr_db"
DB_USER="bcr_user"
DB_PASS="votre_mot_de_passe_securise"

# Sauvegarde BDD
mysqldump -u$DB_USER -p$DB_PASS $DB_NAME > $BACKUP_DIR/bcr_db_$DATE.sql

# Sauvegarde uploads
tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz /var/www/bcr-app/public/api/uploads/

# Nettoyage (garder 30 jours)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Sauvegarde terminée: $DATE"
```

---

## 🖼️ Gestion des Images

### Configuration PHP
```php
<?php
// /var/www/bcr-app/public/api/config/upload.php

class UploadConfig {
    const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
    const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf'];
    const UPLOAD_PATH = '/var/www/bcr-app/public/api/uploads/';
    
    public static function getUploadPath($type) {
        $paths = [
            'accidents' => self::UPLOAD_PATH . 'accidents/',
            'contraventions' => self::UPLOAD_PATH . 'contraventions/',
            'particuliers' => self::UPLOAD_PATH . 'particuliers/',
            'entreprises' => self::UPLOAD_PATH . 'entreprises/'
        ];
        
        return $paths[$type] ?? self::UPLOAD_PATH;
    }
    
    public static function validateFile($file) {
        if ($file['size'] > self::MAX_FILE_SIZE) {
            throw new Exception('Fichier trop volumineux');
        }
        
        if (!in_array($file['type'], self::ALLOWED_TYPES)) {
            throw new Exception('Type de fichier non autorisé');
        }
        
        return true;
    }
}
?>
```

### Optimisation Images
```bash
#!/bin/bash
# Script d'optimisation automatique des images

find /var/www/bcr-app/public/api/uploads/ -name "*.jpg" -o -name "*.jpeg" | while read img; do
    jpegoptim --max=85 --strip-all "$img"
done

find /var/www/bcr-app/public/api/uploads/ -name "*.png" | while read img; do
    optipng -o2 "$img"
done
```

---

## 🌐 Configuration Domaine

### DNS Records
```
# Zone DNS pour heaventech.net
controls.heaventech.net.   A     123.456.789.10
api.bcr.heaventech.net.    A     123.456.789.10
```

### Sous-domaines
```apache
# Sous-domaine API dédié (optionnel)
<VirtualHost *:443>
    ServerName api.bcr.votre-domaine.com
    DocumentRoot /var/www/bcr-app/public/api
    
    # Configuration SSL identique
    # ... SSL config ...
    
    # CORS pour sous-domaine
    Header always set Access-Control-Allow-Origin "https://bcr.votre-domaine.com"
    Header always set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
    Header always set Access-Control-Allow-Headers "Content-Type, Authorization"
</VirtualHost>
```

---

## 🔒 SSL et Sécurité

### Installation Let's Encrypt
```bash
# Installation Certbot
sudo apt update
sudo apt install certbot python3-certbot-apache

# Génération certificat
sudo certbot --apache -d api.bcr.heaventech.net -d bcr.heaventech.net -d www.bcr.heaventech.net

# Renouvellement automatique
sudo crontab -e
# Ajouter: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Configuration Sécurité PHP
```php
<?php
// /var/www/bcr-app/public/api/config/security.php

// Headers sécurité
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Strict-Transport-Security: max-age=31536000; includeSubDomains');

// CORS sécurisé
$allowed_origins = [
    'https://controls.heaventech.net',
    'https://control.heaventech.net',
    'https://api.bcr.heaventech.net'
];

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (in_array($origin, $allowed_origins)) {
    header("Access-Control-Allow-Origin: $origin");
} else {
    header('Access-Control-Allow-Origin: https://controls.heaventech.net');
}

header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Protection CSRF
session_start();
if (!isset($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}
?>
```

---

## 🚀 Déploiement

### Script de Déploiement
```bash
#!/bin/bash
# /var/www/bcr-app/scripts/deploy.sh

set -e

echo "🚀 Début du déploiement BCR..."

# Variables
APP_DIR="/var/www/bcr-app"
BACKUP_DIR="$APP_DIR/private/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Sauvegarde avant déploiement
echo "📦 Sauvegarde pré-déploiement..."
$APP_DIR/scripts/backup.sh

# Build Flutter Web
echo "🔨 Build Flutter Web..."
cd /path/to/flutter/bcr
flutter build web --release

# Déploiement Frontend
echo "📱 Déploiement Frontend..."
rm -rf $APP_DIR/public/index.html $APP_DIR/public/main.dart.js $APP_DIR/public/assets
cp -r build/web/* $APP_DIR/public/

# Déploiement API
echo "🔧 Déploiement API..."
rsync -av --exclude='uploads/' api/ $APP_DIR/public/api/

# Permissions
echo "🔐 Configuration permissions..."
chown -R www-data:www-data $APP_DIR/public
chmod -R 755 $APP_DIR/public
chmod -R 777 $APP_DIR/public/api/uploads

# Redémarrage services
echo "🔄 Redémarrage services..."
systemctl reload apache2
systemctl restart php8.1-fpm

echo "✅ Déploiement terminé avec succès!"
```

---

## 📊 Monitoring

### Logs à Surveiller
```bash
# Logs Apache/Nginx
tail -f /var/www/bcr-app/private/logs/error.log
tail -f /var/www/bcr-app/private/logs/access.log

# Logs PHP
tail -f /var/log/php8.1-fpm.log

# Logs MySQL
tail -f /var/log/mysql/error.log
```

### Script de Monitoring
```bash
#!/bin/bash
# Vérification santé application

# Vérifier site web
curl -f https://api.bcr.heaventech.net > /dev/null || echo "ERREUR: Site inaccessible"

# Vérifier API avec route de santé
curl -f https://api.bcr.heaventech.net/api/routes/index.php/health > /dev/null || echo "ERREUR: API inaccessible"

# Test complet de l'API
curl https://api.bcr.heaventech.net/api/routes/index.php/test

# Vérifier MySQL
mysqladmin -u bcr_user -p ping > /dev/null || echo "ERREUR: MySQL inaccessible"

# Vérifier espace disque
df -h | awk '$5 > 80 {print "ATTENTION: Disque plein sur " $6}'
```

---

## 📝 Configuration Production Flutter

### Mise à jour ApiConfig
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String _prodUrl = 'bcr.votre-domaine.com';
  
  static String get baseUrl {
    if (kDebugMode) {
      return 'http://localhost:8000/api/routes/index.php';
    }
    return 'https://$_prodUrl/api/routes/index.php';
  }
  
  static String get imageBaseUrl {
    if (kDebugMode) {
      return 'http://localhost:8000';
    }
    return 'https://$_prodUrl';
  }
}
```

---

## ✅ Checklist Déploiement

- [ ] Serveur configuré (Apache/Nginx)
- [ ] MySQL installé et configuré
- [ ] PHP 8.1+ installé
- [ ] Certificat SSL configuré
- [ ] DNS pointé vers le serveur
- [ ] Base de données importée
- [ ] Permissions fichiers configurées
- [ ] Scripts de sauvegarde en place
- [ ] Monitoring configuré
- [ ] Tests de fonctionnement effectués

---

**📞 Support Technique**
- Documentation complète dans `/docs/`
- Logs dans `/private/logs/`
- Scripts maintenance dans `/scripts/`
