<?php
/**
 * Test de connexion réel pour l'utilisateur "testes"
 */

header('Content-Type: text/plain; charset=utf-8');

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/controllers/AuthController.php';

echo "=== TEST DE CONNEXION UTILISATEUR 'testes' ===\n\n";

$database = new Database();
$db = $database->getConnection();

if (!$db) {
    echo "❌ Erreur de connexion à la base de données\n";
    exit(1);
}

$authController = new AuthController();

echo "🕐 Heure actuelle du serveur: " . date('Y-m-d H:i:s') . "\n";
echo "📅 Jour: " . date('N') . " (" . date('l') . ")\n\n";

echo "🔐 Tentative de connexion...\n";
echo "  - Matricule: testes\n";
echo "  - Mot de passe: testes\n\n";

$result = $authController->login('testes', 'testes');

echo "📋 Résultat:\n";
print_r($result);

if ($result['success'] === true) {
    echo "\n✅ CONNEXION RÉUSSIE (PROBLÈME !)\n";
    echo "L'utilisateur a pu se connecter alors qu'il ne devrait pas.\n";
} else {
    echo "\n❌ CONNEXION REFUSÉE (CORRECT !)\n";
    echo "Message: " . $result['message'] . "\n";
}
?>
