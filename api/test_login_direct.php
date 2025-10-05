<?php
/**
 * Test direct de l'authentification sans passer par le routeur complet
 */

// Activer l'affichage des erreurs
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "=== TEST DIRECT DE L'AUTHENTIFICATION ===\n\n";

try {
    // Inclure les dépendances
    require_once __DIR__ . '/controllers/AuthController.php';
    
    echo "✅ AuthController chargé avec succès\n";
    
    // Tester la connexion à la base de données
    $authController = new AuthController();
    echo "✅ Instance AuthController créée\n";
    
    // Test de connexion pour l'utilisateur boom
    $matricule = 'boom';
    $password = 'boombeach';
    
    echo "Test de connexion pour: $matricule\n";
    
    $result = $authController->login($matricule, $password);
    
    echo "Résultat de la connexion:\n";
    print_r($result);
    
    if ($result['success']) {
        echo "\n✅ SUCCÈS - L'authentification fonctionne!\n";
        echo "Le problème vient probablement du routeur ou de la configuration du serveur web.\n";
    } else {
        echo "\n❌ ÉCHEC - Problème d'authentification\n";
        echo "Message: {$result['message']}\n";
    }
    
} catch (Exception $e) {
    echo "❌ ERREUR: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
} catch (Error $e) {
    echo "❌ ERREUR FATALE: " . $e->getMessage() . "\n";
    echo "Fichier: " . $e->getFile() . " ligne " . $e->getLine() . "\n";
}

echo "\n=== DIAGNOSTIC ===\n";
echo "Si l'authentification fonctionne ici mais pas via l'API,\n";
echo "le problème est dans le routeur ou la configuration du serveur.\n";
?>
