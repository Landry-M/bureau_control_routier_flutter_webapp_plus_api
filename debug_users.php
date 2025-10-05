<?php
// Script pour déboguer le problème de connexion des utilisateurs

require_once __DIR__ . '/api/config/database.php';

echo "=== Debug des utilisateurs BCR ===\n\n";

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        echo "❌ Erreur: Impossible de se connecter à la base de données\n";
        exit(1);
    }
    
    echo "✅ Connexion à la base de données réussie\n\n";
    
    // Vérifier si la table users existe
    $stmt = $db->query("SHOW TABLES LIKE 'users'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Erreur: La table 'users' n'existe pas\n";
        exit(1);
    }
    
    echo "✅ Table 'users' trouvée\n\n";
    
    // Afficher la structure de la table
    echo "📋 Structure de la table users:\n";
    $stmt = $db->query("DESCRIBE users");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo "  - {$row['Field']} ({$row['Type']}) {$row['Null']} {$row['Key']}\n";
    }
    echo "\n";
    
    // Lister tous les utilisateurs
    echo "👥 Utilisateurs dans la base de données:\n";
    $stmt = $db->query("SELECT id, matricule, username, nom, prenom, role, password, statut, first_connection FROM users ORDER BY id");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($users)) {
        echo "❌ Aucun utilisateur trouvé dans la base de données\n\n";
        
        // Créer des utilisateurs de test
        echo "🔧 Création d'utilisateurs de test...\n";
        
        $testUsers = [
            [
                'matricule' => 'landry',
                'username' => 'Landry Admin',
                'nom' => 'Landry',
                'prenom' => 'Admin',
                'role' => 'admin',
                'password' => md5('landr1'),
                'statut' => 'actif',
                'first_connection' => 'false'
            ],
            [
                'matricule' => 'admin',
                'username' => 'Admin System',
                'nom' => 'Admin',
                'prenom' => 'System',
                'role' => 'admin',
                'password' => md5('password123'),
                'statut' => 'actif',
                'first_connection' => 'false'
            ],
            [
                'matricule' => 'police001',
                'username' => 'Agent Police',
                'nom' => 'Agent',
                'prenom' => 'Police',
                'role' => 'agent',
                'password' => md5('police123'),
                'statut' => 'actif',
                'first_connection' => 'false'
            ],
            [
                'matricule' => 'super',
                'username' => 'Super Admin',
                'nom' => 'Super',
                'prenom' => 'Admin',
                'role' => 'superadmin',
                'password' => md5('super123'),
                'statut' => 'actif',
                'first_connection' => 'false'
            ]
        ];
        
        foreach ($testUsers as $user) {
            try {
                $insertStmt = $db->prepare("INSERT INTO users (matricule, username, nom, prenom, role, password, statut, first_connection, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())");
                $insertStmt->execute([
                    $user['matricule'],
                    $user['username'],
                    $user['nom'],
                    $user['prenom'],
                    $user['role'],
                    $user['password'],
                    $user['statut'],
                    $user['first_connection']
                ]);
                echo "  ✅ Utilisateur créé: {$user['matricule']} (role: {$user['role']})\n";
            } catch (Exception $e) {
                echo "  ❌ Erreur création {$user['matricule']}: " . $e->getMessage() . "\n";
            }
        }
        
        echo "\n🔄 Relecture des utilisateurs...\n";
        $stmt = $db->query("SELECT id, matricule, username, nom, prenom, role, password, statut, first_connection FROM users ORDER BY id");
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    foreach ($users as $user) {
        echo "  ID: {$user['id']}\n";
        echo "  Matricule: {$user['matricule']}\n";
        echo "  Username: {$user['username']}\n";
        echo "  Nom: {$user['nom']} {$user['prenom']}\n";
        echo "  Rôle: {$user['role']}\n";
        echo "  Password (MD5): {$user['password']}\n";
        echo "  Statut: {$user['statut']}\n";
        echo "  Première connexion: {$user['first_connection']}\n";
        echo "  ---\n";
    }
    
    echo "\n🧪 Test de connexion pour chaque utilisateur:\n";
    
    // Tester les mots de passe
    $testCredentials = [
        ['matricule' => 'landry', 'password' => 'landr1'],
        ['matricule' => 'admin', 'password' => 'password123'],
        ['matricule' => 'police001', 'password' => 'police123'],
        ['matricule' => 'super', 'password' => 'super123']
    ];
    
    foreach ($testCredentials as $cred) {
        $matricule = $cred['matricule'];
        $password = $cred['password'];
        $passwordMd5 = md5($password);
        
        echo "  Test: {$matricule} / {$password}\n";
        
        $stmt = $db->prepare("SELECT * FROM users WHERE matricule = ? OR username = ? LIMIT 1");
        $stmt->execute([$matricule, $matricule]);
        
        if ($stmt->rowCount() > 0) {
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            $storedPassword = $user['password'] ?? $user['mot_de_passe'] ?? '';
            
            echo "    Utilisateur trouvé: {$user['username']}\n";
            echo "    Password stocké: {$storedPassword}\n";
            echo "    Password testé (MD5): {$passwordMd5}\n";
            
            if ($passwordMd5 === $storedPassword) {
                echo "    ✅ CONNEXION RÉUSSIE\n";
            } else {
                echo "    ❌ ÉCHEC - Mot de passe incorrect\n";
            }
        } else {
            echo "    ❌ ÉCHEC - Utilisateur non trouvé\n";
        }
        echo "\n";
    }
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}

echo "=== Fin du debug ===\n";
?>
