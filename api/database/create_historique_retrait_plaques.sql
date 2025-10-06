-- Table pour l'historique des retraits de plaques
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

-- Index pour améliorer les performances de recherche
CREATE INDEX idx_vehicule_plaque_id ON historique_retrait_plaques(vehicule_plaque_id);
CREATE INDEX idx_date_retrait ON historique_retrait_plaques(date_retrait);
