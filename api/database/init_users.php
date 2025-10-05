<?php
/**
 * Script d'initialisation des utilisateurs par défaut
 * Exécute ce script pour créer les utilisateurs de base du système
 */

require_once __DIR__ . '/../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        throw new Exception('Impossible de se connecter à la base de données');
    }
    
    echo "Connexion à la base de données réussie.\n";
    
    // Vérifier si la table users existe
    $checkTable = $db->query("SHOW TABLES LIKE 'users'");
    if ($checkTable->rowCount() == 0) {
        echo "La table 'users' n'existe pas. Création de la table...\n";
        
        // Créer la table users si elle n'existe pas
        $createTableSQL = "
        CREATE TABLE users (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            matricule VARCHAR(100) UNIQUE NOT NULL,
            username VARCHAR(255) NOT NULL,
            nom VARCHAR(255),
            prenom VARCHAR(255),
            email VARCHAR(255),
            telephone VARCHAR(20),
            role VARCHAR(50) DEFAULT 'agent',
            password VARCHAR(255) NOT NULL,
            statut VARCHAR(20) DEFAULT 'actif',
            first_connection VARCHAR(10) DEFAULT 'true',
            login_schedule TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            
            INDEX idx_matricule (matricule),
            INDEX idx_role (role),
            INDEX idx_statut (statut)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ";
        
        $db->exec($createTableSQL);
        echo "Table 'users' créée avec succès.\n";
    }
    
    // Utilisateurs par défaut selon les mémoires
    $defaultUsers = [
        [
            'matricule' => 'admin',
            'username' => 'Administrateur',
            'password' => 'password123', // MD5: 482c811da5d5b4bc6d497ffa98491e38
            'role' => 'admin',
            'first_connection' => 'false'
        ],
        [
            'matricule' => 'police001',
            'username' => 'Agent Police 001',
            'password' => 'police123', // MD5: 9b2c2d4b3c6b8f4e7d5a1c3e6f8b2d4a
            'role' => 'agent',
            'first_connection' => 'false'
        ],
        [
            'matricule' => 'super',
            'username' => 'Super Administrateur',
            'password' => 'super123', // MD5: 2ac9cb7dc02b3c0083eb70898e549b63
            'role' => 'superadmin',
            'first_connection' => 'false'
        ],
        [
            'matricule' => 'landry',
            'username' => 'Landry',
            'password' => 'landr1', // MD5: b0e69c61cf08f6e6ce12b4575886407d
            'role' => 'superadmin',
            'first_connection' => 'false'
        ]
    ];
    
    echo "Ajout des utilisateurs par défaut...\n";
    
    foreach ($defaultUsers as $user) {
        // Vérifier si l'utilisateur existe déjà
        $checkUser = $db->prepare("SELECT id FROM users WHERE matricule = :matricule");
        $checkUser->bindParam(':matricule', $user['matricule']);
        $checkUser->execute();
        
        if ($checkUser->rowCount() > 0) {
            echo "L'utilisateur '{$user['matricule']}' existe déjà. Mise à jour...\n";
            
            // Mettre à jour l'utilisateur existant
            $updateSQL = "UPDATE users SET 
                         username = :username,
                         password = :password,
                         role = :role,
                         first_connection = :first_connection,
                         statut = 'actif',
                         updated_at = NOW()
                         WHERE matricule = :matricule";
            
            $updateStmt = $db->prepare($updateSQL);
            $updateStmt->bindParam(':username', $user['username']);
            $updateStmt->bindParam(':password', md5($user['password']));
            $updateStmt->bindParam(':role', $user['role']);
            $updateStmt->bindParam(':first_connection', $user['first_connection']);
            $updateStmt->bindParam(':matricule', $user['matricule']);
            
            if ($updateStmt->execute()) {
                echo "✅ Utilisateur '{$user['matricule']}' mis à jour avec succès.\n";
            } else {
                echo "❌ Erreur lors de la mise à jour de l'utilisateur '{$user['matricule']}'.\n";
            }
        } else {
            echo "Création de l'utilisateur '{$user['matricule']}'...\n";
            
            // Créer le nouvel utilisateur
            $insertSQL = "INSERT INTO users (matricule, username, password, role, first_connection, statut, created_at, updated_at) 
                         VALUES (:matricule, :username, :password, :role, :first_connection, 'actif', NOW(), NOW())";
            
            $insertStmt = $db->prepare($insertSQL);
            $insertStmt->bindParam(':matricule', $user['matricule']);
            $insertStmt->bindParam(':username', $user['username']);
            $insertStmt->bindParam(':password', md5($user['password']));
            $insertStmt->bindParam(':role', $user['role']);
            $insertStmt->bindParam(':first_connection', $user['first_connection']);
            
            if ($insertStmt->execute()) {
                echo "✅ Utilisateur '{$user['matricule']}' créé avec succès.\n";
            } else {
                echo "❌ Erreur lors de la création de l'utilisateur '{$user['matricule']}'.\n";
            }
        }
    }
    
    echo "\n=== RÉSUMÉ DES UTILISATEURS ===\n";
    
    // Afficher tous les utilisateurs
    $allUsers = $db->query("SELECT matricule, username, role, statut, first_connection FROM users ORDER BY id");
    while ($user = $allUsers->fetch(PDO::FETCH_ASSOC)) {
        echo "- Matricule: {$user['matricule']} | Nom: {$user['username']} | Rôle: {$user['role']} | Statut: {$user['statut']}\n";
    }
    
    echo "\n=== IDENTIFIANTS DE CONNEXION ===\n";
    echo "1. admin / password123 (rôle: admin)\n";
    echo "2. police001 / police123 (rôle: agent)\n";
    echo "3. super / super123 (rôle: superadmin)\n";
    echo "4. landry / landr1 (rôle: superadmin)\n";
    echo "\nInitialisation terminée avec succès !\n";
    
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
    exit(1);
}
?>
