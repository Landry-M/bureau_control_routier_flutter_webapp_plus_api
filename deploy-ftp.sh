#!/bin/bash
# Script de déploiement FTP pour controls.heaventech.net

echo "🚀 Déploiement FTP controls.heaventech.net..."

# Variables FTP - MODIFIEZ CES VALEURS
FTP_HOST="ftp.votre-hebergeur.com"
FTP_USER="votre_username_ftp"
FTP_PASS="votre_password_ftp"
FTP_PATH="/public_html/api_bcr/controls-app"
LOCAL_PROJECT="/Users/apple/Documents/dev/flutter/bcr"

echo "📍 Serveur FTP: $FTP_HOST"
echo "📍 Chemin distant: $FTP_PATH"

# 1. Build Flutter Web
echo "🔨 Build Flutter Web..."
cd $LOCAL_PROJECT
flutter clean
flutter build web --release

# 2. Upload via lftp (plus robuste que ftp)
echo "📤 Upload des fichiers..."

# Installation de lftp si nécessaire (macOS)
if ! command -v lftp &> /dev/null; then
    echo "📦 Installation de lftp..."
    brew install lftp
fi

# Script lftp
lftp -c "
set ftp:ssl-allow no
open -u $FTP_USER,$FTP_PASS $FTP_HOST
lcd $LOCAL_PROJECT
cd $FTP_PATH

# Création des dossiers
mkdir -p api
mkdir -p uploads
mkdir -p uploads/accidents
mkdir -p uploads/contraventions
mkdir -p uploads/particuliers

# Upload Flutter
mirror --reverse --delete build/web/ ./

# Upload API
mirror --reverse --delete api/ api/

# Upload .htaccess
put .htaccess-controls .htaccess

# Upload uploads (si existant)
mirror --reverse uploads/ uploads/

quit
"

echo "✅ Déploiement FTP terminé!"
echo "🌐 App: https://controls.heaventech.net/"
