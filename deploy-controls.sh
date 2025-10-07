#!/bin/bash
# Script de déploiement automatisé pour controls.heaventech.net

set -e

echo "🚀 Déploiement controls.heaventech.net..."

# Variables - MODIFIEZ CES VALEURS
LOCAL_PROJECT="/Users/apple/Documents/dev/flutter/bcr"
REMOTE_SERVER="ngla4195@controls.heaventech.net"  # ← CHANGEZ: votre username
REMOTE_PATH="public_html/api_bcr/controls-app"  # ← Votre chemin exact
SSH_KEY="id_rsa"  # ← CHANGEZ: chemin vers votre clé privée
DATE=$(date +%Y%m%d_%H%M%S)

# Options SSH avec clé
SSH_OPTIONS="-i $SSH_KEY -o StrictHostKeyChecking=no"

echo "📍 Chemin local: $LOCAL_PROJECT"
echo "📍 Serveur distant: $REMOTE_SERVER"
echo "📍 Chemin distant: $REMOTE_PATH"

# 1. Build Flutter Web
echo "🔨 Build Flutter Web..."
cd $LOCAL_PROJECT
flutter clean
flutter build web --release

# Vérification du build
if [ ! -d "build/web" ]; then
    echo "❌ Erreur: Build Flutter échoué"
    exit 1
fi

echo "✅ Build Flutter terminé"

# 2. Sauvegarde distante
echo "📦 Sauvegarde de l'existant..."
ssh $SSH_OPTIONS $REMOTE_SERVER "mkdir -p /tmp/backups && tar -czf /tmp/backups/backup_controls_$DATE.tar.gz -C $REMOTE_PATH . 2>/dev/null || echo 'Pas de fichiers existants à sauvegarder'"

# 3. Création des dossiers distants
echo "📁 Création des dossiers..."
ssh $SSH_OPTIONS $REMOTE_SERVER "
    mkdir -p $REMOTE_PATH
    mkdir -p $REMOTE_PATH/api
    mkdir -p $REMOTE_PATH/uploads
    mkdir -p $REMOTE_PATH/uploads/accidents
    mkdir -p $REMOTE_PATH/uploads/contraventions
    mkdir -p $REMOTE_PATH/uploads/particuliers
    mkdir -p $REMOTE_PATH/uploads/entreprises
    mkdir -p $REMOTE_PATH/uploads/conducteurs
"

# 4. Déploiement Flutter
echo "📱 Déploiement Flutter Web..."
rsync -avz --delete -e "ssh $SSH_OPTIONS" build/web/ $REMOTE_SERVER:$REMOTE_PATH/

# 5. Déploiement API
echo "🔧 Déploiement API..."
rsync -avz --exclude='uploads/' -e "ssh $SSH_OPTIONS" api/ $REMOTE_SERVER:$REMOTE_PATH/api/

# 6. Synchronisation uploads (préservation des fichiers existants)
echo "📁 Synchronisation uploads..."
rsync -avz -e "ssh $SSH_OPTIONS" uploads/ $REMOTE_SERVER:$REMOTE_PATH/uploads/

# 7. Configuration .htaccess
echo "⚙️ Configuration .htaccess..."
scp $SSH_OPTIONS .htaccess-controls $REMOTE_SERVER:$REMOTE_PATH/.htaccess

# 8. Permissions
echo "🔐 Configuration permissions..."
ssh $SSH_OPTIONS $REMOTE_SERVER "
    # Permissions générales
    find $REMOTE_PATH -type d -exec chmod 755 {} \;
    find $REMOTE_PATH -type f -exec chmod 644 {} \;
    
    # Permissions spéciales pour uploads
    chmod -R 777 $REMOTE_PATH/uploads
    
    # Permissions pour .htaccess
    chmod 644 $REMOTE_PATH/.htaccess
    
    # Permissions pour les fichiers PHP
    find $REMOTE_PATH/api -name '*.php' -exec chmod 644 {} \;
"

# 9. Test de santé
echo "🏥 Tests de santé..."

# Test 1: Page d'accueil
echo "🧪 Test 1: Page d'accueil..."
if curl -f -s https://controls.heaventech.net/ > /dev/null; then
    echo "✅ App accessible"
else
    echo "⚠️ App non accessible"
fi

# Test 2: API Health
echo "🧪 Test 2: API Health..."
if curl -f -s https://controls.heaventech.net/api/routes/index.php > /dev/null; then
    echo "✅ API accessible"
else
    echo "⚠️ API non accessible"
fi

# Test 3: Dossier uploads
echo "🧪 Test 3: Dossier uploads..."
if curl -f -s -I https://controls.heaventech.net/uploads/ > /dev/null; then
    echo "✅ Uploads accessible"
else
    echo "⚠️ Uploads non accessible (normal si vide)"
fi

# 10. Résumé
echo ""
echo "🎉 Déploiement terminé!"
echo "📊 Résumé:"
echo "   🌐 App: https://controls.heaventech.net/"
echo "   🔧 API: https://controls.heaventech.net/api/routes/index.php"
echo "   📁 Uploads: https://controls.heaventech.net/uploads/"
echo "   💾 Sauvegarde: /tmp/backups/backup_controls_$DATE.tar.gz"
echo ""
echo "🔍 Prochaines étapes:"
echo "   1. Testez l'application dans votre navigateur"
echo "   2. Vérifiez que le login fonctionne"
echo "   3. Testez l'upload d'images"
echo "   4. Vérifiez qu'il n'y a plus d'erreurs CORS"
echo ""
echo "✅ Déploiement réussi!"
