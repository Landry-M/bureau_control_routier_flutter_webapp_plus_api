#!/bin/bash

# Script pour redémarrer le serveur PHP avec les nouvelles configurations

echo "🔄 Redémarrage du serveur PHP avec les nouvelles limites..."

# Arrêter le serveur s'il est en cours d'exécution
echo "📍 Arrêt du serveur existant..."
pkill -f "php -S localhost:8000"

# Attendre un moment
sleep 2

# Redémarrer le serveur avec le fichier php.ini local
echo "🚀 Démarrage du serveur avec les nouvelles configurations..."
cd /Users/apple/Documents/dev/flutter/bcr
php -S localhost:8000 -c api/php.ini &

# Attendre que le serveur démarre
sleep 3

echo "✅ Serveur redémarré avec les nouvelles limites PHP !"
echo "📊 Vérifiez les limites à : http://localhost:8000/api/check_php_limits.php"
echo "🔗 Testez les plaques temporaires maintenant !"

# Afficher les processus PHP en cours
echo "📋 Processus PHP actifs :"
ps aux | grep "php -S" | grep -v grep
