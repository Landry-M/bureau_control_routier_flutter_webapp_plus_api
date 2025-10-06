<?php
echo "=== CRÉATION TABLE PERMIS_TEMPORAIRE ===\n\n";

try {
    $pdo = new PDO('mysql:host=localhost;dbname=control_routier', 'root', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "Connexion à la base de données réussie\n";
    
    // Vérifier si la table existe déjà
    $stmt = $pdo->query("SHOW TABLES LIKE 'permis_temporaire'");
    if ($stmt->rowCount() > 0) {
        echo "⚠️ Table permis_temporaire existe déjà\n";
        
        // Afficher la structure actuelle
        $stmt = $pdo->query("DESCRIBE permis_temporaire");
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo "Structure actuelle:\n";
        foreach ($columns as $column) {
            echo "  - {$column['Field']}: {$column['Type']} {$column['Null']} {$column['Key']} {$column['Default']} {$column['Extra']}\n";
        }
        
        // Vérifier si l'AUTO_INCREMENT est bien configuré
        $stmt = $pdo->query("SHOW CREATE TABLE permis_temporaire");
        $createTable = $stmt->fetch(PDO::FETCH_ASSOC);
        if (strpos($createTable['Create Table'], 'AUTO_INCREMENT') === false) {
            echo "❌ AUTO_INCREMENT manquant, correction en cours...\n";
            $pdo->exec("ALTER TABLE permis_temporaire MODIFY id int(10) UNSIGNED NOT NULL AUTO_INCREMENT");
            echo "✅ AUTO_INCREMENT ajouté\n";
        } else {
            echo "✅ AUTO_INCREMENT déjà configuré\n";
        }
    } else {
        echo "Création de la table permis_temporaire...\n";
        
        $sql = "
        CREATE TABLE `permis_temporaire` (
          `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
          `cible_type` enum('particulier','conducteur','vehicule_plaque') NOT NULL DEFAULT 'particulier',
          `cible_id` bigint(20) UNSIGNED NOT NULL,
          `numero` varchar(50) NOT NULL,
          `motif` text DEFAULT NULL,
          `date_debut` date NOT NULL,
          `date_fin` date NOT NULL,
          `statut` enum('actif','clos') NOT NULL DEFAULT 'actif',
          `pdf_path` varchar(255) DEFAULT NULL COMMENT 'Chemin relatif vers le fichier PDF généré',
          `created_by` varchar(100) DEFAULT NULL,
          `created_at` datetime NOT NULL,
          `updated_at` datetime NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `uniq_permis_temporaire_numero` (`numero`),
          KEY `idx_permis_temporaire_cible` (`cible_type`,`cible_id`),
          KEY `idx_permis_temporaire_statut` (`statut`),
          KEY `idx_permis_temporaire_pdf_path` (`pdf_path`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ";
        
        $pdo->exec($sql);
        echo "✅ Table permis_temporaire créée avec succès\n";
    }
    
    // Test d'insertion
    echo "\nTest d'insertion...\n";
    $testData = [
        'cible_type' => 'particulier',
        'cible_id' => 1,
        'numero' => 'PT' . date('Ym') . '0001',
        'motif' => 'Test de création',
        'date_debut' => '2025-01-10',
        'date_fin' => '2025-02-10',
        'created_by' => 'test',
        'created_at' => date('Y-m-d H:i:s'),
        'updated_at' => date('Y-m-d H:i:s')
    ];
    
    $sql = "INSERT INTO permis_temporaire (cible_type, cible_id, numero, motif, date_debut, date_fin, created_by, created_at, updated_at) 
            VALUES (:cible_type, :cible_id, :numero, :motif, :date_debut, :date_fin, :created_by, :created_at, :updated_at)";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute($testData);
    
    $insertId = $pdo->lastInsertId();
    echo "✅ Test d'insertion réussi, ID: $insertId\n";
    
    // Supprimer le test
    $pdo->exec("DELETE FROM permis_temporaire WHERE id = $insertId");
    echo "✅ Données de test supprimées\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}

echo "\n=== FIN ===\n";
?>
