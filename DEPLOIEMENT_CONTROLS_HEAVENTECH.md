# 🚀 Guide de Déploiement - controls.heaventech.net

## 📋 Architecture Simplifiée (Sans CORS)

**Domaine unique :** `controls.heaventech.net`
- **App Flutter** : `https://controls.heaventech.net/`
- **API PHP** : `https://controls.heaventech.net/api/routes/index.php`
- **Images** : `https://controls.heaventech.net/uploads/accidents/image.jpg`

---

## 📁 Structure du Serveur

```
/var/www/controls-app/public/           # Document Root
├── index.html                          # Flutter Web (point d'entrée)
├── main.dart.js                        # Flutter compilé
├── flutter.js                          # Runtime Flutter
├── favicon.png                         # Icône
├── manifest.json                       # Manifest PWA
├── assets/                             # Assets Flutter
│   ├── AssetManifest.json
│   ├── FontManifest.json
│   ├── fonts/
│   └── packages/
├── api/                                # API PHP
│   ├── routes/
│   │   └── index.php                   # Point d'entrée API
│   ├── controllers/                    # Contrôleurs métier
│   │   ├── AccidentController.php
│   │   ├── VehiculeController.php
│   │   ├── ParticulierController.php
│   │   ├── EntrepriseController.php
│   │   ├── AuthController.php
│   │   └── ...
│   ├── config/
│   │   └── database.php                # Configuration BDD
│   └── database/                       # Scripts SQL
└── uploads/                            # Fichiers uploadés
    ├── accidents/
    ├── contraventions/
    ├── particuliers/
    └── entreprises/
```

---

## ⚙️ Configuration Apache

### **Virtual Host Complet**

```apache
# /etc/apache2/sites-available/controls.conf
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
    
    # Flutter Web - SPA Routing
    <Directory "/var/www/controls-app/public">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        
        # Fallback pour Flutter Router (IMPORTANT !)
        FallbackResource /index.html
    </Directory>
    
    # API PHP - Pas de CORS nécessaire !
    <Directory "/var/www/controls-app/public/api">
        Options -Indexes
        AllowOverride All
        Require all granted
    </Directory>
    
    # Protection uploads - seulement images et PDFs
    <Directory "/var/www/controls-app/public/uploads">
        Options -Indexes -ExecCGI
        AllowOverride None
        <FilesMatch "\.(jpg|jpeg|png|gif|pdf)$">
            Require all granted
        </FilesMatch>
        <FilesMatch "\.php$">
            Require all denied
        </FilesMatch>
    </Directory>
    
    # Headers de sécurité
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Compression GZIP
    LoadModule deflate_module modules/mod_deflate.so
    <Location />
        SetOutputFilter DEFLATE
        SetEnvIfNoCase Request_URI \
            \.(?:gif|jpe?g|png)$ no-gzip dont-vary
        SetEnvIfNoCase Request_URI \
            \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
    </Location>
    
    # Cache pour assets statiques
    <FilesMatch "\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)$">
        ExpiresActive On
        ExpiresDefault "access plus 1 month"
        Header set Cache-Control "public, immutable"
    </FilesMatch>
    
    # Pas de cache pour index.html (mises à jour app)
    <FilesMatch "index\.html$">
        ExpiresActive On
        ExpiresDefault "access plus 0 seconds"
        Header set Cache-Control "no-cache, no-store, must-revalidate"
        Header set Pragma "no-cache"
    </FilesMatch>
    
    # Logs
    ErrorLog /var/www/controls-app/logs/error.log
    CustomLog /var/www/controls-app/logs/access.log combined
</VirtualHost>
```

---

## 📄 Configuration .htaccess

### **Fichier .htaccess Principal**

```apache
# /var/www/controls-app/public/.htaccess

# Configuration PHP pour uploads
php_value upload_max_filesize 100M
php_value post_max_size 100M
php_value max_execution_time 600
php_value max_input_time 600
php_value memory_limit 512M
php_value max_input_vars 3000
php_flag file_uploads On

# Flutter Web - SPA Routing
RewriteEngine On
RewriteBase /

# Ne pas réécrire les fichiers existants
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d

# Exceptions pour l'API et uploads
RewriteCond %{REQUEST_URI} !^/api/
RewriteCond %{REQUEST_URI} !^/uploads/

# Rediriger vers index.html pour Flutter Router
RewriteRule . /index.html [L]

# Compression GZIP
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
    AddOutputFilterByType DEFLATE application/json
</IfModule>

# Types MIME
AddType application/javascript .js
AddType text/css .css
AddType application/json .json

# Configuration pour les fichiers PHP
<Files "*.php">
    php_value upload_max_filesize 100M
    php_value post_max_size 100M
    php_value max_execution_time 600
    php_value max_input_time 600
    php_value memory_limit 512M
    php_value max_input_vars 3000
    php_flag file_uploads On
</Files>
```

---

## 🔒 SSL avec Let's Encrypt

### **Installation et Configuration**

```bash
# Installation Certbot
sudo apt update
sudo apt install certbot python3-certbot-apache

# Génération certificat pour controls.heaventech.net
sudo certbot --apache -d controls.heaventech.net

# Vérification du certificat
sudo certbot certificates

# Test de renouvellement
sudo certbot renew --dry-run

# Renouvellement automatique (crontab)
sudo crontab -e
# Ajouter : 0 12 * * * /usr/bin/certbot renew --quiet
```

---

## 🚀 Script de Déploiement

### **Script Automatisé**

```bash
#!/bin/bash
# deploy-controls.sh

set -e

echo "🚀 Déploiement controls.heaventech.net..."

# Variables
LOCAL_PROJECT="/Users/apple/Documents/dev/flutter/bcr"
REMOTE_SERVER="user@controls.heaventech.net"
REMOTE_PATH="/var/www/controls-app/public"
DATE=$(date +%Y%m%d_%H%M%S)

# 1. Build Flutter Web
echo "🔨 Build Flutter Web..."
cd $LOCAL_PROJECT
flutter build web --release

# 2. Sauvegarde distante
echo "📦 Sauvegarde de l'existant..."
ssh $REMOTE_SERVER "tar -czf /tmp/backup_controls_$DATE.tar.gz -C $REMOTE_PATH . 2>/dev/null || true"

# 3. Déploiement Flutter
echo "📱 Déploiement Flutter Web..."
rsync -avz --delete build/web/ $REMOTE_SERVER:$REMOTE_PATH/

# 4. Déploiement API
echo "🔧 Déploiement API..."
rsync -avz --exclude='uploads/' api/ $REMOTE_SERVER:$REMOTE_PATH/api/

# 5. Déploiement uploads (si nécessaire)
echo "📁 Synchronisation uploads..."
rsync -avz uploads/ $REMOTE_SERVER:$REMOTE_PATH/uploads/

# 6. Configuration .htaccess
echo "⚙️ Configuration .htaccess..."
scp .htaccess-controls $REMOTE_SERVER:$REMOTE_PATH/.htaccess

# 7. Permissions
echo "🔐 Configuration permissions..."
ssh $REMOTE_SERVER "
    chown -R www-data:www-data $REMOTE_PATH
    chmod -R 755 $REMOTE_PATH
    chmod -R 777 $REMOTE_PATH/uploads
    chmod 644 $REMOTE_PATH/.htaccess
"

# 8. Test de santé
echo "🏥 Test de santé..."
curl -f https://controls.heaventech.net/api/routes/index.php/health || echo "⚠️ API non accessible"

echo "✅ Déploiement terminé avec succès!"
echo "🌐 App: https://controls.heaventech.net/"
echo "🔧 API: https://controls.heaventech.net/api/routes/index.php/health"
```

---

## 📋 Checklist de Déploiement

### **Avant le Déploiement :**
- [ ] Flutter build web --release exécuté
- [ ] Base de données configurée et accessible
- [ ] Certificat SSL généré pour controls.heaventech.net
- [ ] DNS pointant vers le bon serveur
- [ ] Dossiers de logs créés

### **Déploiement :**
- [ ] Fichiers Flutter copiés dans /public/
- [ ] API copiée dans /public/api/
- [ ] Uploads synchronisés dans /public/uploads/
- [ ] .htaccess configuré
- [ ] Permissions définies (www-data:www-data)

### **Tests Post-Déploiement :**
- [ ] App accessible : https://controls.heaventech.net/
- [ ] API fonctionnelle : https://controls.heaventech.net/api/routes/index.php/health
- [ ] Login fonctionne
- [ ] Images s'affichent
- [ ] Pas d'erreurs CORS dans la console

---

## 🔧 Dépannage

### **Problèmes Courants :**

**1. App ne charge pas :**
```bash
# Vérifier les logs Apache
tail -f /var/www/controls-app/logs/error.log
```

**2. API inaccessible :**
```bash
# Test direct
curl https://controls.heaventech.net/api/routes/index.php/health
```

**3. Routing Flutter ne fonctionne pas :**
```apache
# Vérifier FallbackResource dans .htaccess
FallbackResource /index.html
```

**4. Images ne s'affichent pas :**
```bash
# Vérifier permissions uploads
ls -la /var/www/controls-app/public/uploads/
```

---

## 📞 Support

### **Logs à Vérifier :**
- Apache : `/var/www/controls-app/logs/error.log`
- PHP : `/var/log/php/error.log`
- SSL : `/var/log/letsencrypt/letsencrypt.log`

### **Tests de Validation :**
```bash
# Test complet
curl -I https://controls.heaventech.net/
curl https://controls.heaventech.net/api/routes/index.php/health
curl -I https://controls.heaventech.net/uploads/
```

---

**🎯 Avec cette configuration, plus aucun problème CORS ! Tout fonctionne sur le même domaine.**
