<?php
/**
 * Script pour lister tous les utilisateurs et leurs informations
 */

require_once __DIR__ . '/../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        throw new Exception('Impossible de se connecter à la base de données');
    }
    
    echo "=== LISTE DE TOUS LES UTILISATEURS ===\n\n";
    
    $query = "SELECT matricule, username, role, statut, first_connection, password, created_at FROM users ORDER BY id";
    $stmt = $db->query($query);
    
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($users as $user) {
        echo "Matricule: {$user['matricule']}\n";
        echo "Nom: {$user['username']}\n";
        echo "Rôle: {$user['role']}\n";
        echo "Statut: {$user['statut']}\n";
        echo "Première connexion: {$user['first_connection']}\n";
        echo "Hash MD5 du mot de passe: {$user['password']}\n";
        echo "Créé le: {$user['created_at']}\n";
        
        // Essayer de deviner le mot de passe pour les utilisateurs existants
        $commonPasswords = ['123456', 'password', 'admin', $user['matricule'], $user['matricule'] . '123'];
        $foundPassword = null;
        
        foreach ($commonPasswords as $testPassword) {
            if (md5($testPassword) === $user['password']) {
                $foundPassword = $testPassword;
                break;
            }
        }
        
        if ($foundPassword) {
            echo "🔓 Mot de passe probable: {$foundPassword}\n";
        } else {
            echo "🔒 Mot de passe non identifié\n";
        }
        
        echo "----------------------------------------\n";
    }
    
    echo "\n=== IDENTIFIANTS CONFIRMÉS ===\n";
    echo "admin / password123\n";
    echo "police001 / police123\n";
    echo "super / super123\n";
    echo "landry / landr1\n";
    echo "\nPour les autres utilisateurs, essayez des mots de passe courants\n";
    echo "ou contactez l'administrateur système.\n";
    
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
}
?>
