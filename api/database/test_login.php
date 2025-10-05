<?php
/**
 * Script de test des connexions utilisateurs
 */

require_once __DIR__ . '/../controllers/AuthController.php';

$testUsers = [
    ['matricule' => 'admin', 'password' => 'password123'],
    ['matricule' => 'police001', 'password' => 'police123'],
    ['matricule' => 'super', 'password' => 'super123'],
    ['matricule' => 'landry', 'password' => 'landr1'],
    ['matricule' => 'test000', 'password' => 'wrongpassword'], // Test avec mauvais mot de passe
];

echo "=== TEST DES CONNEXIONS UTILISATEURS ===\n\n";

$authController = new AuthController();

foreach ($testUsers as $user) {
    echo "Test de connexion pour: {$user['matricule']}\n";
    echo "Mot de passe: {$user['password']}\n";
    
    $result = $authController->login($user['matricule'], $user['password']);
    
    if ($result['success']) {
        echo "✅ SUCCÈS - Connexion réussie\n";
        echo "   Rôle: {$result['role']}\n";
        echo "   Nom: {$result['username']}\n";
        echo "   Première connexion: " . ($result['first_connection'] ? 'Oui' : 'Non') . "\n";
    } else {
        echo "❌ ÉCHEC - {$result['message']}\n";
    }
    
    echo "----------------------------------------\n";
}

echo "\n=== RÉSUMÉ ===\n";
echo "Si tous les utilisateurs (sauf test000) se connectent avec succès,\n";
echo "alors le problème de l'erreur 501 est résolu.\n";
?>
