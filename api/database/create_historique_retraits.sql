-- Table pour l'historique des retraits de plaques
CREATE TABLE IF NOT EXISTS historique_retraits_plaque (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vehicule_plaque_id INT NOT NULL,
    plaque_retiree VARCHAR(255) NOT NULL,
    date_retrait DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motif TEXT,
    agent_username VARCHAR(255),
    observations TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicule_plaque_id) REFERENCES vehicule_plaque(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Index pour améliorer les performances
CREATE INDEX idx_vehicule_plaque_id ON historique_retraits_plaque(vehicule_plaque_id);
CREATE INDEX idx_date_retrait ON historique_retraits_plaque(date_retrait);
