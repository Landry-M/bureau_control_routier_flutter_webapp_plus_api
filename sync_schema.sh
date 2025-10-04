#!/bin/bash

# Script de synchronisation automatique du schéma de base de données
# À exécuter chaque fois que vous modifiez la structure de la DB

echo "🔄 Synchronisation du schéma de base de données..."

# 1. Générer la documentation
echo "📝 Génération de la documentation..."
php /Users/apple/Documents/dev/flutter/bcr/api/database/generate_schema.php

# 2. Vérifier si les fichiers ont été créés
if [ -f "/Users/apple/Documents/dev/flutter/bcr/api/database/schema.json" ]; then
    echo "✅ Fichier schema.json créé"
else
    echo "❌ Erreur: schema.json non créé"
    exit 1
fi

if [ -f "/Users/apple/Documents/dev/flutter/bcr/api/database/schema_documentation.md" ]; then
    echo "✅ Fichier documentation créé"
else
    echo "❌ Erreur: documentation non créée"
    exit 1
fi

# 3. Tester l'endpoint API
echo "🧪 Test de l'endpoint /schema..."
response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/bcr/api/routes/index.php?route=/schema")

if [ "$response" = "200" ]; then
    echo "✅ Endpoint /schema fonctionne"
else
    echo "⚠️  Endpoint /schema retourne: $response"
fi

echo ""
echo "📋 Fichiers générés:"
echo "   - api/database/schema.json (pour l'API)"
echo "   - api/database/schema_documentation.md (lisible)"
echo ""
echo "🌐 Endpoints disponibles:"
echo "   - GET /schema (structure complète)"
echo "   - GET /logs (rapports d'activités)"
echo ""
echo "✨ Synchronisation terminée!"
