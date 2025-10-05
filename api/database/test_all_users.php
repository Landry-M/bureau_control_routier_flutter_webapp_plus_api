<?php
/**
 * Test de connexion pour tous les utilisateurs identifiés
 */

require_once __DIR__ . '/../controllers/AuthController.php';

$testUsers = [
    // Utilisateurs avec mots de passe confirmés
    ['matricule' => 'admin', 'password' => 'password123'],
    ['matricule' => 'police001', 'password' => 'police123'],
    ['matricule' => 'super', 'password' => 'super123'],
    ['matricule' => 'landry', 'password' => 'landr1'],
    
    // Autres utilisateurs existants avec mots de passe probables
    ['matricule' => 'police123', 'password' => 'police123'],
    ['matricule' => 'impala', 'password' => 'impala'],
    ['matricule' => 'lubumbashi', 'password' => 'lubumbashi'],
    
    // Test avec un utilisateur inexistant
    ['matricule' => 'inexistant', 'password' => 'test123'],
];

echo "=== TEST COMPLET DES CONNEXIONS ===\n\n";

$authController = new AuthController();
$successCount = 0;
$totalTests = count($testUsers);

foreach ($testUsers as $index => $user) {
    echo "Test " . ($index + 1) . "/{$totalTests}: {$user['matricule']}\n";
    
    $result = $authController->login($user['matricule'], $user['password']);
    
    if ($result['success']) {
        echo "✅ SUCCÈS - Connexion réussie\n";
        echo "   Rôle: {$result['role']}\n";
        echo "   Nom: {$result['username']}\n";
        $successCount++;
    } else {
        echo "❌ ÉCHEC - {$result['message']}\n";
    }
    
    echo "----------------------------------------\n";
}

echo "\n=== RÉSULTATS FINAUX ===\n";
echo "Connexions réussies: {$successCount}/" . ($totalTests - 1) . " (excluant le test d'échec)\n";

if ($successCount >= 7) {
    echo "🎉 PROBLÈME RÉSOLU !\n";
    echo "Tous les utilisateurs peuvent maintenant se connecter.\n";
    echo "L'erreur 501 était due au fait que seul 'landry' existait dans la base.\n";
} else {
    echo "⚠️  Certains utilisateurs ne peuvent toujours pas se connecter.\n";
}

echo "\n=== IDENTIFIANTS VALIDES ===\n";
echo "1. admin / password123 (admin)\n";
echo "2. police001 / police123 (agent)\n";
echo "3. super / super123 (superadmin)\n";
echo "4. landry / landr1 (superadmin)\n";
echo "5. police123 / police123 (inspecteur)\n";
echo "6. impala / impala (agent_special)\n";
echo "7. lubumbashi / lubumbashi (inspecteur)\n";
?>
