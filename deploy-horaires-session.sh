#!/bin/bash

# Script de déploiement des fichiers pour le système de vérification des horaires
# Usage: ./deploy-horaires-session.sh

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Déploiement - Système de vérification des horaires       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérifier que les fichiers existent
echo "🔍 Vérification des fichiers..."

FILES_TO_DEPLOY=(
    "api/check_session_schedule.php"
    "api/config/timezone.php"
    "api/config/database.php"
)

MISSING_FILES=0
for file in "${FILES_TO_DEPLOY[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file ${RED}(MANQUANT)${NC}"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

echo ""

if [ $MISSING_FILES -gt 0 ]; then
    echo -e "${RED}❌ $MISSING_FILES fichier(s) manquant(s)${NC}"
    echo "Impossible de continuer le déploiement."
    exit 1
fi

echo -e "${GREEN}✅ Tous les fichiers sont présents${NC}"
echo ""

# Demander les informations de connexion FTP
echo "📋 Configuration du serveur FTP"
echo "────────────────────────────────────────────────────────────"

read -p "Hôte FTP (ex: ftp.votre-serveur.com): " FTP_HOST
read -p "Nom d'utilisateur: " FTP_USER
read -sp "Mot de passe: " FTP_PASS
echo ""
read -p "Chemin distant (ex: /public_html/api): " FTP_PATH

echo ""
echo "🚀 Démarrage du déploiement..."
echo ""

# Créer un fichier de commandes FTP temporaire
FTP_SCRIPT=$(mktemp)

cat > "$FTP_SCRIPT" <<EOF
open $FTP_HOST
user $FTP_USER $FTP_PASS
binary
cd $FTP_PATH
put api/check_session_schedule.php check_session_schedule.php
cd config
put api/config/timezone.php timezone.php
put api/config/database.php database.php
bye
EOF

# Exécuter le transfert FTP
if ftp -n < "$FTP_SCRIPT"; then
    echo ""
    echo -e "${GREEN}✅ Déploiement réussi !${NC}"
    echo ""
    echo "Fichiers déployés :"
    echo "  • $FTP_PATH/check_session_schedule.php"
    echo "  • $FTP_PATH/config/timezone.php"
    echo "  • $FTP_PATH/config/database.php"
    echo ""
    echo "🧪 Test de l'endpoint :"
    echo "  curl https://$FTP_HOST/api/check_session_schedule.php?user_id=1"
else
    echo ""
    echo -e "${RED}❌ Erreur lors du déploiement${NC}"
    echo "Vérifiez vos identifiants FTP et réessayez."
    rm -f "$FTP_SCRIPT"
    exit 1
fi

# Nettoyer le fichier temporaire
rm -f "$FTP_SCRIPT"

echo ""
echo "📝 Prochaines étapes :"
echo "  1. Vérifier que l'endpoint fonctionne"
echo "  2. Tester la connexion avec un utilisateur restreint"
echo "  3. Rebuild et déployer l'application Flutter"
echo ""
echo -e "${GREEN}✨ Terminé !${NC}"
