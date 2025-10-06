<?php
/**
 * Script d'initialisation de la table historique_retrait_plaques
 * Exécuter ce script pour créer la table dans la base de données
 */

require_once __DIR__ . '/../config/database.php';

try {
    $database = new Database();
    $pdo = $database->getConnection();
    
    echo "=== Création de la table historique_retrait_plaques ===\n\n";
    
    // Créer la table
    $sql = "
        CREATE TABLE IF NOT EXISTS historique_retrait_plaques (
            id INT AUTO_INCREMENT PRIMARY KEY,
            vehicule_plaque_id INT NOT NULL,
            ancienne_plaque VARCHAR(50) NOT NULL,
            date_retrait DATETIME NOT NULL,
            motif VARCHAR(255) DEFAULT NULL,
            observations TEXT DEFAULT NULL,
            username VARCHAR(100) DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (vehicule_plaque_id) REFERENCES vehicule_plaque(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ";
    
    $pdo->exec($sql);
    echo "✅ Table historique_retrait_plaques créée avec succès\n\n";
    
    // Créer les index
    echo "Création des index...\n";
    
    $indexes = [
        "CREATE INDEX IF NOT EXISTS idx_vehicule_plaque_id ON historique_retrait_plaques(vehicule_plaque_id)",
        "CREATE INDEX IF NOT EXISTS idx_date_retrait ON historique_retrait_plaques(date_retrait)"
    ];
    
    foreach ($indexes as $index) {
        try {
            $pdo->exec($index);
            echo "✅ Index créé\n";
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'Duplicate key') !== false) {
                echo "ℹ️  Index déjà existant\n";
            } else {
                throw $e;
            }
        }
    }
    
    echo "\n=== Initialisation terminée avec succès ===\n";
    echo "\nStructure de la table :\n";
    echo "- id : Clé primaire\n";
    echo "- vehicule_plaque_id : Référence au véhicule\n";
    echo "- ancienne_plaque : Plaque retirée\n";
    echo "- date_retrait : Date et heure du retrait\n";
    echo "- motif : Motif du retrait (optionnel)\n";
    echo "- observations : Observations supplémentaires (optionnel)\n";
    echo "- username : Utilisateur qui a effectué le retrait\n";
    echo "- created_at : Date de création de l'enregistrement\n";
    
} catch (PDOException $e) {
    echo "❌ Erreur : " . $e->getMessage() . "\n";
    exit(1);
}
