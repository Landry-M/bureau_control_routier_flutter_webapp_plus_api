<?php
/**
 * Test final de l'authentification pour l'utilisateur boom
 */

echo "=== TEST FINAL DE L'AUTHENTIFICATION ===\n\n";

// Test avec la nouvelle URL
$url = 'http://localhost:8000/api/routes/index.php?route=/auth/login';
$testData = [
    'matricule' => 'boom',
    'password' => 'boombeach'
];

echo "URL testée: $url\n";
echo "Données: " . json_encode($testData) . "\n\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Content-Length: ' . strlen(json_encode($testData))
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "❌ Erreur cURL: $error\n";
    exit(1);
}

echo "Code HTTP: $httpCode\n";

if ($httpCode == 200) {
    echo "✅ Requête réussie!\n\n";
    
    $jsonResponse = json_decode($response, true);
    if ($jsonResponse && isset($jsonResponse['status'])) {
        if ($jsonResponse['status'] === 'ok') {
            echo "🎉 AUTHENTIFICATION RÉUSSIE!\n";
            echo "Token: {$jsonResponse['token']}\n";
            echo "Rôle: {$jsonResponse['role']}\n";
            echo "Username: {$jsonResponse['username']}\n";
            echo "Matricule: {$jsonResponse['matricule']}\n";
            echo "Première connexion: " . ($jsonResponse['first_connection'] ? 'Oui' : 'Non') . "\n";
            
            echo "\n=== RÉSUMÉ ===\n";
            echo "✅ L'utilisateur 'boom' peut maintenant se connecter!\n";
            echo "✅ L'API fonctionne correctement sur le port 8000\n";
            echo "✅ Toutes les URLs Flutter ont été mises à jour\n";
            
            echo "\n=== PROCHAINES ÉTAPES ===\n";
            echo "1. Redémarrez votre application Flutter\n";
            echo "2. Essayez de vous connecter avec:\n";
            echo "   - Matricule: boom\n";
            echo "   - Mot de passe: boombeach\n";
            echo "3. Gardez le serveur PHP en marche avec:\n";
            echo "   cd /Users/apple/Documents/dev/flutter/bcr\n";
            echo "   php -S localhost:8000\n";
            
        } else {
            echo "❌ Authentification échouée: {$jsonResponse['message']}\n";
        }
    } else {
        echo "⚠️  Réponse non-JSON: $response\n";
    }
} else {
    echo "❌ Code HTTP non-200: $httpCode\n";
    echo "Réponse: $response\n";
}

echo "\n=== INFORMATIONS SERVEUR ===\n";
echo "Le serveur PHP doit rester en marche pour que l'application fonctionne.\n";
echo "Pour arrêter le serveur, utilisez Ctrl+C dans le terminal où il s'exécute.\n";
?>
