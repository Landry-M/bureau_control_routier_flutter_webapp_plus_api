<?php
// Test de l'endpoint /contravention/{id}/display
echo "=== Test de l'endpoint /contravention/{id}/display ===\n\n";

// Configuration
$baseUrl = 'http://localhost:8000/api/routes/index.php';
$contraventionId = 23; // ID de test

echo "1. Test de l'endpoint display...\n";
echo "URL testée: $baseUrl/contravention/$contraventionId/display\n\n";

// Test avec cURL
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "$baseUrl/contravention/$contraventionId/display");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, false); // Ne pas suivre les redirections
curl_setopt($ch, CURLOPT_HEADER, true); // Inclure les headers dans la réponse

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "❌ Erreur cURL: $error\n";
} else {
    echo "📊 Code de réponse HTTP: $httpCode\n";
    
    if ($httpCode === 302) {
        echo "✅ Redirection détectée (attendue)\n";
        
        // Extraire l'URL de redirection
        if (preg_match('/Location: (.+)/', $response, $matches)) {
            $redirectUrl = trim($matches[1]);
            echo "🔗 URL de redirection: $redirectUrl\n";
            
            if (strpos($redirectUrl, 'contravention_display.php') !== false) {
                echo "✅ Redirection vers contravention_display.php correcte\n";
            } else {
                echo "❌ Redirection incorrecte\n";
            }
        }
    } elseif ($httpCode === 200) {
        echo "✅ Réponse OK\n";
    } else {
        echo "❌ Code d'erreur inattendu\n";
        echo "Réponse:\n$response\n";
    }
}

echo "\n2. Test de l'existence du fichier contravention_display.php...\n";

$displayFile = __DIR__ . '/contravention_display.php';
if (file_exists($displayFile)) {
    echo "✅ Fichier contravention_display.php existe\n";
    echo "📁 Chemin: $displayFile\n";
    
    // Vérifier les permissions
    if (is_readable($displayFile)) {
        echo "✅ Fichier lisible\n";
    } else {
        echo "❌ Fichier non lisible\n";
    }
} else {
    echo "❌ Fichier contravention_display.php manquant\n";
    echo "📁 Chemin attendu: $displayFile\n";
}

echo "\n3. Test direct du fichier contravention_display.php...\n";

$directUrl = "http://localhost:8000/contravention_display.php?id=$contraventionId";
echo "URL directe: $directUrl\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $directUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, true);
curl_setopt($ch, CURLOPT_NOBODY, true); // HEAD request

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "📊 Code de réponse HTTP (direct): $httpCode\n";

if ($httpCode === 200) {
    echo "✅ Fichier contravention_display.php accessible directement\n";
} else {
    echo "❌ Fichier contravention_display.php non accessible\n";
}

echo "\n4. Vérification de la base de données...\n";

try {
    require_once 'api/config/database.php';
    $pdo = getDbConnection();
    
    $stmt = $pdo->prepare("SELECT id, type_dossier, date_infraction, lieu FROM contraventions WHERE id = ?");
    $stmt->execute([$contraventionId]);
    $contravention = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($contravention) {
        echo "✅ Contravention ID $contraventionId trouvée en base\n";
        echo "📋 Type: " . ($contravention['type_dossier'] ?? 'N/A') . "\n";
        echo "📅 Date: " . ($contravention['date_infraction'] ?? 'N/A') . "\n";
        echo "📍 Lieu: " . ($contravention['lieu'] ?? 'N/A') . "\n";
    } else {
        echo "❌ Contravention ID $contraventionId non trouvée en base\n";
        
        // Lister quelques contraventions existantes
        $stmt = $pdo->query("SELECT id FROM contraventions ORDER BY id DESC LIMIT 5");
        $existingIds = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        if (!empty($existingIds)) {
            echo "📋 IDs de contraventions existantes: " . implode(', ', $existingIds) . "\n";
            echo "💡 Essayez avec un de ces IDs\n";
        } else {
            echo "❌ Aucune contravention en base\n";
        }
    }
    
} catch (Exception $e) {
    echo "❌ Erreur base de données: " . $e->getMessage() . "\n";
}

echo "\n=== Résumé ===\n";
echo "🎯 Endpoint à tester: /contravention/{id}/display\n";
echo "🔗 Doit rediriger vers: /contravention_display.php?id={id}\n";
echo "📱 Utilisé par: Boutons 'œil' dans Flutter\n";

echo "\n=== Recommandations ===\n";
echo "1. ✅ Vérifier que le serveur web est démarré\n";
echo "2. ✅ Vérifier que l'ID de contravention existe\n";
echo "3. ✅ Tester avec un ID valide\n";
echo "4. ✅ Vérifier les permissions du fichier contravention_display.php\n";

echo "\n=== Test terminé ===\n";
?>
