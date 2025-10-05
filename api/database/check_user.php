<?php
/**
 * Script pour vérifier un utilisateur spécifique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../controllers/AuthController.php';

$matricule = 'boom';
$password = 'boombeach';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        throw new Exception('Impossible de se connecter à la base de données');
    }
    
    echo "=== VÉRIFICATION DE L'UTILISATEUR 'boom' ===\n\n";
    
    // 1. Vérifier si l'utilisateur existe
    $query = "SELECT * FROM users WHERE matricule = :matricule OR username = :matricule";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':matricule', $matricule);
    $stmt->execute();
    
    if ($stmt->rowCount() > 0) {
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        echo "✅ Utilisateur trouvé dans la base de données :\n";
        echo "   ID: {$user['id']}\n";
        echo "   Matricule: {$user['matricule']}\n";
        echo "   Username: {$user['username']}\n";
        echo "   Rôle: {$user['role']}\n";
        echo "   Statut: {$user['statut']}\n";
        echo "   Première connexion: {$user['first_connection']}\n";
        echo "   Hash MD5 stocké: {$user['password']}\n";
        echo "   Hash MD5 de 'boombeach': " . md5($password) . "\n";
        
        // Vérifier si les mots de passe correspondent
        if (md5($password) === $user['password']) {
            echo "   ✅ Les mots de passe correspondent\n";
        } else {
            echo "   ❌ Les mots de passe ne correspondent PAS\n";
        }
        
        echo "\n";
        
        // 2. Tester la connexion via AuthController
        echo "=== TEST DE CONNEXION ===\n";
        $authController = new AuthController();
        $result = $authController->login($matricule, $password);
        
        if ($result['success']) {
            echo "✅ SUCCÈS - Connexion réussie via AuthController\n";
            echo "   Token: {$result['token']}\n";
            echo "   Rôle: {$result['role']}\n";
            echo "   Username: {$result['username']}\n";
        } else {
            echo "❌ ÉCHEC - {$result['message']}\n";
        }
        
    } else {
        echo "❌ Utilisateur 'boom' NON TROUVÉ dans la base de données\n";
        echo "L'utilisateur doit être créé d'abord.\n";
        
        // Lister tous les utilisateurs pour vérification
        echo "\n=== UTILISATEURS EXISTANTS ===\n";
        $allUsers = $db->query("SELECT matricule, username FROM users ORDER BY id");
        while ($user = $allUsers->fetch(PDO::FETCH_ASSOC)) {
            echo "- {$user['matricule']} ({$user['username']})\n";
        }
    }
    
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
}
?>
