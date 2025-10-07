<?php
/**
 * Script d'initialisation des tables pour les parties impliquées dans les accidents
 */

require_once __DIR__ . '/../config/database.php';

echo "=== Initialisation des tables parties impliquées ===\n\n";

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    if (!$conn) {
        die("Erreur: Impossible de se connecter à la base de données\n");
    }
    
    echo "✓ Connexion à la base de données réussie\n\n";
    
    // 1. Créer la table parties_impliquees
    echo "Création de la table parties_impliquees...\n";
    $sql = "CREATE TABLE IF NOT EXISTS parties_impliquees (
        id BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
        accident_id BIGINT(20) NOT NULL,
        vehicule_plaque_id BIGINT(20) NULL,
        role ENUM('responsable', 'victime', 'temoin_materiel', 'autre') DEFAULT 'autre',
        conducteur_nom VARCHAR(255) NULL,
        conducteur_etat ENUM('indemne', 'blesse_leger', 'blesse_grave', 'decede') DEFAULT 'indemne',
        dommages_vehicule TEXT NULL,
        photos TEXT NULL COMMENT 'JSON array des chemins des photos',
        notes TEXT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (accident_id) REFERENCES accidents(id) ON DELETE CASCADE,
        FOREIGN KEY (vehicule_plaque_id) REFERENCES vehicule_plaque(id) ON DELETE SET NULL,
        INDEX idx_accident_id (accident_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
    
    $conn->exec($sql);
    echo "✓ Table parties_impliquees créée avec succès\n\n";
    
    // 2. Créer la table passagers_partie
    echo "Création de la table passagers_partie...\n";
    $sql = "CREATE TABLE IF NOT EXISTS passagers_partie (
        id BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
        partie_id BIGINT(20) NOT NULL,
        nom VARCHAR(255) NOT NULL,
        etat ENUM('indemne', 'blesse_leger', 'blesse_grave', 'decede') DEFAULT 'indemne',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (partie_id) REFERENCES parties_impliquees(id) ON DELETE CASCADE,
        INDEX idx_partie_id (partie_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
    
    $conn->exec($sql);
    echo "✓ Table passagers_partie créée avec succès\n\n";
    
    // 3. Vérifier si les colonnes existent déjà dans accidents
    echo "Mise à jour de la table accidents...\n";
    
    // Vérifier les colonnes existantes
    $result = $conn->query("SHOW COLUMNS FROM accidents LIKE 'services_etat_present'");
    if ($result->rowCount() == 0) {
        $conn->exec("ALTER TABLE accidents ADD COLUMN services_etat_present TEXT NULL COMMENT 'JSON array des services présents'");
        echo "✓ Colonne services_etat_present ajoutée\n";
    } else {
        echo "→ Colonne services_etat_present existe déjà\n";
    }
    
    $result = $conn->query("SHOW COLUMNS FROM accidents LIKE 'partie_fautive_id'");
    if ($result->rowCount() == 0) {
        $conn->exec("ALTER TABLE accidents ADD COLUMN partie_fautive_id BIGINT(20) NULL COMMENT 'ID de la partie responsable'");
        echo "✓ Colonne partie_fautive_id ajoutée\n";
    } else {
        echo "→ Colonne partie_fautive_id existe déjà\n";
    }
    
    $result = $conn->query("SHOW COLUMNS FROM accidents LIKE 'raison_faute'");
    if ($result->rowCount() == 0) {
        $conn->exec("ALTER TABLE accidents ADD COLUMN raison_faute TEXT NULL COMMENT 'Explication de la responsabilité'");
        echo "✓ Colonne raison_faute ajoutée\n";
    } else {
        echo "→ Colonne raison_faute existe déjà\n";
    }
    
    $result = $conn->query("SHOW COLUMNS FROM accidents LIKE 'updated_at'");
    if ($result->rowCount() == 0) {
        $conn->exec("ALTER TABLE accidents ADD COLUMN updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP");
        echo "✓ Colonne updated_at ajoutée\n";
    } else {
        echo "→ Colonne updated_at existe déjà\n";
    }
    
    echo "\n";
    
    // 4. Créer les dossiers uploads nécessaires
    echo "Création des dossiers uploads...\n";
    
    $uploadDirs = [
        __DIR__ . '/../../uploads/parties_impliquees',
        __DIR__ . '/../../uploads/accidents'
    ];
    
    foreach ($uploadDirs as $dir) {
        if (!is_dir($dir)) {
            mkdir($dir, 0777, true);
            echo "✓ Dossier créé: " . basename($dir) . "\n";
        } else {
            echo "→ Dossier existe déjà: " . basename($dir) . "\n";
        }
    }
    
    echo "\n=== ✓ Initialisation terminée avec succès ===\n";
    
} catch (PDOException $e) {
    echo "❌ ERREUR PDO: " . $e->getMessage() . "\n";
    exit(1);
} catch (Exception $e) {
    echo "❌ ERREUR: " . $e->getMessage() . "\n";
    exit(1);
}
?>
