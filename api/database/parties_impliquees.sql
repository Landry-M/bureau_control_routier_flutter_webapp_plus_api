-- Table pour les parties impliquées dans un accident
CREATE TABLE IF NOT EXISTS parties_impliquees (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table pour les passagers de chaque partie
CREATE TABLE IF NOT EXISTS passagers_partie (
    id BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    partie_id BIGINT(20) NOT NULL,
    nom VARCHAR(255) NOT NULL,
    etat ENUM('indemne', 'blesse_leger', 'blesse_grave', 'decede') DEFAULT 'indemne',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (partie_id) REFERENCES parties_impliquees(id) ON DELETE CASCADE,
    INDEX idx_partie_id (partie_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Mise à jour de la table accidents pour les nouveaux champs
ALTER TABLE accidents 
ADD COLUMN IF NOT EXISTS services_etat_present TEXT NULL COMMENT 'JSON array des services présents: police, ambulance, pompiers, etc.',
ADD COLUMN IF NOT EXISTS partie_fautive_id BIGINT(20) NULL COMMENT 'ID de la partie responsable',
ADD COLUMN IF NOT EXISTS raison_faute TEXT NULL COMMENT 'Explication de la responsabilité',
ADD COLUMN IF NOT EXISTS updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
