# 🔒 Documentation CORS - Configuration Hébergement

## 📋 Table des Matières
1. [Qu'est-ce que CORS ?](#quest-ce-que-cors)
2. [Configuration Actuelle](#configuration-actuelle)
3. [Configuration Hébergeur](#configuration-hébergeur)
4. [Résolution des Problèmes](#résolution-des-problèmes)
5. [Tests et Validation](#tests-et-validation)
6. [Configurations Alternatives](#configurations-alternatives)

---

## 🤔 Qu'est-ce que CORS ?

**CORS (Cross-Origin Resource Sharing)** est un mécanisme de sécurité qui permet ou bloque les requêtes entre différents domaines.

### **Votre Architecture :**
- **Frontend** : `https://controls.heaventech.net` (Flutter Web)
- **Backend API** : `https://api.bcr.heaventech.net` (PHP)

Sans CORS, le navigateur **bloque** les requêtes de `controls.heaventech.net` vers `api.bcr.heaventech.net`.

---

## ⚙️ Configuration Actuelle

### **1. Configuration PHP (`/api/routes/index.php`)**

```php
// Configuration CORS sécurisée
$allowed_origins = [
    'https://controls.heaventech.net',    // Votre app Flutter
    'https://api.bcr.heaventech.net',     // Votre API
    'http://localhost:3000',              // Développement Flutter
    'http://localhost:8000',              // Développement PHP
    'http://127.0.0.1:3000',             // Alternative localhost
    'http://127.0.0.1:8000'              // Alternative localhost
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
```

### **2. Configuration Apache (`.htaccess`)**

```apache
# Headers CORS sécurisés
SetEnvIf Origin "^https://controls\.heaventech\.net$" CORS_ORIGIN=$0
SetEnvIf Origin "^https://api\.bcr\.heaventech\.net$" CORS_ORIGIN=$0
SetEnvIf Origin "^http://localhost:8000$" CORS_ORIGIN=$0
SetEnvIf Origin "^http://127\.0\.0\.1:8000$" CORS_ORIGIN=$0

Header always set Access-Control-Allow-Origin "%{CORS_ORIGIN}e" env=CORS_ORIGIN
Header always set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
Header always set Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With"
Header always set Access-Control-Allow-Credentials "true"
```

---

## 🌐 Configuration Hébergeur

### **A. Configuration cPanel**

Si votre hébergeur utilise cPanel :

#### **1. Via Gestionnaire de Fichiers :**
1. **Connectez-vous à cPanel**
2. **Ouvrez "Gestionnaire de Fichiers"**
3. **Naviguez vers `public_html/` ou votre dossier web**
4. **Éditez le fichier `.htaccess`**
5. **Ajoutez la configuration CORS** (voir ci-dessus)

#### **2. Via Sous-domaines :**
1. **Allez dans "Sous-domaines"**
2. **Créez `api` pointant vers `/public_html/bcr-api/`**
3. **Créez `controls` pointant vers `/public_html/controls-app/`**

### **B. Configuration Serveur Dédié/VPS**

#### **1. Apache Virtual Hosts :**

```apache
# /etc/apache2/sites-available/controls.conf
<VirtualHost *:443>
    ServerName controls.heaventech.net
    DocumentRoot /var/www/controls-app/public
    
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/controls.heaventech.net/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/controls.heaventech.net/privkey.pem
    
    # Headers de sécurité
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
</VirtualHost>

# /etc/apache2/sites-available/api-bcr.conf
<VirtualHost *:443>
    ServerName api.bcr.heaventech.net
    DocumentRoot /var/www/bcr-api/public
    
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/api.bcr.heaventech.net/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/api.bcr.heaventech.net/privkey.pem
    
    # CORS Configuration
    SetEnvIf Origin "^https://controls\.heaventech\.net$" CORS_ORIGIN=$0
    Header always set Access-Control-Allow-Origin "%{CORS_ORIGIN}e" env=CORS_ORIGIN
    Header always set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
    Header always set Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With"
    Header always set Access-Control-Allow-Credentials "true"
</VirtualHost>
```

#### **2. Activation des Sites :**

```bash
sudo a2ensite controls.conf
sudo a2ensite api-bcr.conf
sudo systemctl reload apache2
```

### **C. Configuration Nginx**

```nginx
# /etc/nginx/sites-available/controls
server {
    listen 443 ssl http2;
    server_name controls.heaventech.net;
    
    root /var/www/controls-app/public;
    index index.html;
    
    # SSL
    ssl_certificate /etc/letsencrypt/live/controls.heaventech.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/controls.heaventech.net/privkey.pem;
    
    # Flutter SPA
    location / {
        try_files $uri $uri/ /index.html;
    }
}

# /etc/nginx/sites-available/api-bcr
server {
    listen 443 ssl http2;
    server_name api.bcr.heaventech.net;
    
    root /var/www/bcr-api/public;
    
    # SSL
    ssl_certificate /etc/letsencrypt/live/api.bcr.heaventech.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.bcr.heaventech.net/privkey.pem;
    
    # CORS Headers
    add_header Access-Control-Allow-Origin "https://controls.heaventech.net" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With" always;
    add_header Access-Control-Allow-Credentials "true" always;
    
    # Handle OPTIONS requests
    if ($request_method = 'OPTIONS') {
        return 204;
    }
    
    # PHP Processing
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

---

## 🔧 Résolution des Problèmes

### **Erreur : "Access to fetch blocked by CORS policy"**

#### **Diagnostic :**
```bash
# Testez les headers CORS
curl -H "Origin: https://controls.heaventech.net" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     https://api.bcr.heaventech.net/api/routes/index.php/health
```

#### **Solutions :**

1. **Vérifiez que l'origine est autorisée :**
   ```php
   // Ajoutez des logs pour débugger
   error_log("Origin reçu: " . ($_SERVER['HTTP_ORIGIN'] ?? 'aucun'));
   ```

2. **Vérifiez les headers retournés :**
   ```bash
   curl -I https://api.bcr.heaventech.net/api/routes/index.php/health
   ```

3. **Testez depuis la console du navigateur :**
   ```javascript
   fetch('https://api.bcr.heaventech.net/api/routes/index.php/health')
     .then(response => response.json())
     .then(data => console.log(data))
     .catch(error => console.error('Erreur:', error));
   ```

### **Erreur : "failed to fetch"**

#### **Causes Possibles :**
- **SSL invalide** : Vérifiez que votre certificat SSL fonctionne
- **DNS incorrect** : Vérifiez que `api.bcr.heaventech.net` pointe vers le bon serveur
- **Firewall** : Vérifiez que le port 443 est ouvert
- **PHP non fonctionnel** : Testez directement l'URL dans le navigateur

#### **Tests :**
```bash
# Test SSL
curl -I https://api.bcr.heaventech.net

# Test DNS
nslookup api.bcr.heaventech.net

# Test API
curl https://api.bcr.heaventech.net/api/routes/index.php/health
```

---

## ✅ Tests et Validation

### **1. Test Manuel dans le Navigateur**

Ouvrez la console développeur sur `https://controls.heaventech.net` et exécutez :

```javascript
// Test simple
fetch('https://api.bcr.heaventech.net/api/routes/index.php/health')
  .then(response => {
    console.log('Status:', response.status);
    console.log('Headers:', response.headers);
    return response.json();
  })
  .then(data => console.log('Data:', data))
  .catch(error => console.error('Erreur CORS:', error));

// Test avec credentials
fetch('https://api.bcr.heaventech.net/api/routes/index.php/test', {
  method: 'GET',
  credentials: 'include',
  headers: {
    'Content-Type': 'application/json'
  }
})
.then(response => response.json())
.then(data => console.log('Test avec credentials:', data));
```

### **2. Test avec curl**

```bash
# Test preflight OPTIONS
curl -X OPTIONS \
  -H "Origin: https://controls.heaventech.net" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v https://api.bcr.heaventech.net/api/routes/index.php/health

# Test GET normal
curl -H "Origin: https://controls.heaventech.net" \
  -v https://api.bcr.heaventech.net/api/routes/index.php/health
```

### **3. Validation des Headers**

Les headers suivants **DOIVENT** être présents dans la réponse :

```
Access-Control-Allow-Origin: https://controls.heaventech.net
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With
Access-Control-Allow-Credentials: true
```

---

## 🔄 Configurations Alternatives

### **A. Si l'hébergeur bloque les headers personnalisés**

Créez un fichier `cors.php` :

```php
<?php
// /api/config/cors.php

function handleCors() {
    $allowed_origins = [
        'https://controls.heaventech.net',
        'https://api.bcr.heaventech.net'
    ];
    
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    
    if (in_array($origin, $allowed_origins)) {
        header("Access-Control-Allow-Origin: $origin");
    }
    
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
    header('Access-Control-Allow-Credentials: true');
    
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}

// Appeler au début de chaque fichier PHP
handleCors();
?>
```

### **B. Configuration via PHP uniquement**

Si `.htaccess` ne fonctionne pas, utilisez seulement PHP :

```php
<?php
// Au début de /api/routes/index.php

// Fonction CORS robuste
function setCorsHeaders() {
    $allowed_origins = [
        'https://controls.heaventech.net',
        'https://api.bcr.heaventech.net',
        'http://localhost:8000'
    ];
    
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    
    // Vérifier l'origine
    if (in_array($origin, $allowed_origins)) {
        header("Access-Control-Allow-Origin: $origin");
    } else {
        // Fallback pour les requêtes directes
        header('Access-Control-Allow-Origin: https://controls.heaventech.net');
    }
    
    // Headers CORS standards
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept');
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400'); // Cache preflight 24h
    
    // Gérer les requêtes OPTIONS
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}

// Appliquer CORS
setCorsHeaders();
?>
```

### **C. Configuration Cloudflare (si utilisé)**

Si vous utilisez Cloudflare :

1. **Allez dans le dashboard Cloudflare**
2. **Sélectionnez votre domaine `heaventech.net`**
3. **Allez dans "Rules" > "Transform Rules"**
4. **Créez une règle "Modify Response Header"**
5. **Configurez :**
   - **If** : `hostname equals api.bcr.heaventech.net`
   - **Then** : 
     - `Access-Control-Allow-Origin` = `https://controls.heaventech.net`
     - `Access-Control-Allow-Methods` = `GET, POST, PUT, DELETE, OPTIONS`
     - `Access-Control-Allow-Headers` = `Content-Type, Authorization, X-Requested-With`

---

## 📞 Support et Dépannage

### **Logs à Vérifier :**

```bash
# Logs Apache
tail -f /var/log/apache2/error.log
tail -f /var/log/apache2/access.log

# Logs PHP
tail -f /var/log/php/error.log

# Logs personnalisés
tail -f /var/www/bcr-api/logs/cors.log
```

### **Script de Debug CORS :**

```php
<?php
// /api/debug-cors.php

header('Content-Type: application/json');

$debug_info = [
    'timestamp' => date('Y-m-d H:i:s'),
    'request_method' => $_SERVER['REQUEST_METHOD'] ?? 'unknown',
    'origin' => $_SERVER['HTTP_ORIGIN'] ?? 'no-origin',
    'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'unknown',
    'referer' => $_SERVER['HTTP_REFERER'] ?? 'no-referer',
    'headers' => getallheaders(),
    'server_name' => $_SERVER['SERVER_NAME'] ?? 'unknown',
    'request_uri' => $_SERVER['REQUEST_URI'] ?? 'unknown'
];

echo json_encode($debug_info, JSON_PRETTY_PRINT);
?>
```

### **Contact Hébergeur :**

Si les problèmes persistent, contactez votre hébergeur avec :

1. **Description du problème** : "Erreurs CORS entre sous-domaines"
2. **Domaines concernés** : `controls.heaventech.net` et `api.bcr.heaventech.net`
3. **Configuration souhaitée** : Headers CORS personnalisés
4. **Fichiers modifiés** : `.htaccess` et fichiers PHP
5. **Logs d'erreur** : Joignez les logs pertinents

---

## ✅ Checklist Déploiement CORS

- [ ] Configuration PHP avec origins autorisées
- [ ] Fichier `.htaccess` avec headers CORS
- [ ] SSL configuré sur les deux domaines
- [ ] DNS pointant vers le bon serveur
- [ ] Test curl réussi
- [ ] Test navigateur réussi
- [ ] Logs sans erreurs CORS
- [ ] Application Flutter fonctionnelle

---

**📧 Cette documentation couvre tous les cas de figure pour configurer CORS avec votre hébergeur. Gardez-la comme référence pour le support technique !**
