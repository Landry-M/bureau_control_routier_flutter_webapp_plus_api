#!/bin/bash

# Script de test CORS pour BCR API
# Teste les headers CORS depuis la ligne de commande

API_URL="http://localhost:8000/api/routes/index.php"
TEST_CORS_URL="$API_URL/test_cors.php"
LOGIN_URL="$API_URL/auth/login"

echo "🚀 Test CORS - BCR API"
echo "🌐 URL de base: $API_URL"
echo "=" $(printf '=%.0s' {1..50})
echo ""

# Test 1: Requête GET basique
echo "🧪 Test 1: Requête GET basique"
echo "URL: $TEST_CORS_URL"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" -H "Origin: https://example.com" "$TEST_CORS_URL")
http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo $response | sed -e 's/HTTPSTATUS:.*//g')

if [ "$http_code" -eq 200 ]; then
    echo "✅ Status: $http_code - SUCCÈS"
    echo "📄 Réponse:"
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
else
    echo "❌ Status: $http_code - ÉCHEC"
    echo "📄 Réponse: $body"
fi
echo ""

# Test 2: Requête OPTIONS (preflight)
echo "🧪 Test 2: Requête OPTIONS (preflight)"
echo "URL: $TEST_CORS_URL"
headers=$(curl -s -I -X OPTIONS \
    -H "Origin: https://example.com" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type,Authorization" \
    "$TEST_CORS_URL")

echo "📄 Headers de réponse:"
echo "$headers" | grep -i "access-control\|http/"
echo ""

# Test 3: Requête POST avec headers custom
echo "🧪 Test 3: Requête POST avec headers custom"
echo "URL: $TEST_CORS_URL"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Origin: https://example.com" \
    -H "Authorization: Bearer test-token" \
    -d '{"test": "cors_post"}' \
    "$TEST_CORS_URL")

http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo $response | sed -e 's/HTTPSTATUS:.*//g')

if [ "$http_code" -eq 200 ]; then
    echo "✅ Status: $http_code - SUCCÈS"
    echo "📄 Réponse:"
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
else
    echo "❌ Status: $http_code - ÉCHEC"
    echo "📄 Réponse: $body"
fi
echo ""

# Test 4: Endpoint de login
echo "🧪 Test 4: Endpoint de login"
echo "URL: $LOGIN_URL"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Origin: https://example.com" \
    -d '{"matricule": "test", "password": "test"}' \
    "$LOGIN_URL")

http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo $response | sed -e 's/HTTPSTATUS:.*//g')

if [ "$http_code" -eq 400 ] || [ "$http_code" -eq 401 ] || [ "$http_code" -eq 200 ]; then
    echo "✅ Status: $http_code - ACCESSIBLE (CORS fonctionne)"
    echo "📄 Réponse:"
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
else
    echo "❌ Status: $http_code - PROBLÈME"
    echo "📄 Réponse: $body"
fi
echo ""

# Test 5: Vérification des headers CORS spécifiques
echo "🧪 Test 5: Vérification des headers CORS"
echo "URL: $TEST_CORS_URL"
cors_headers=$(curl -s -I -H "Origin: https://example.com" "$TEST_CORS_URL" | grep -i "access-control")

if [ -n "$cors_headers" ]; then
    echo "✅ Headers CORS détectés:"
    echo "$cors_headers"
    
    # Vérifier les headers spécifiques
    if echo "$cors_headers" | grep -q "Access-Control-Allow-Origin: \*"; then
        echo "✅ Access-Control-Allow-Origin: * (toutes origines acceptées)"
    else
        echo "⚠️  Access-Control-Allow-Origin: pas configuré pour toutes les origines"
    fi
else
    echo "❌ Aucun header CORS détecté"
fi
echo ""

echo "=" $(printf '=%.0s' {1..50})
echo "✨ Tests CORS terminés"
echo ""
echo "📋 Instructions:"
echo "1. Si tous les tests passent, CORS est correctement configuré"
echo "2. Si des erreurs apparaissent, vérifiez:"
echo "   - Que le serveur PHP est démarré: php -S localhost:8000"
echo "   - Que l'URL de base est correcte: $API_URL"
echo "   - Que les fichiers .htaccess et index.php sont à jour"
echo ""
echo "🌐 Pour tester depuis un navigateur, ouvrez: file://$(pwd)/test_cors.html"
echo "🐛 Pour tester depuis Flutter, exécutez: dart test_cors_flutter.dart"
echo ""
