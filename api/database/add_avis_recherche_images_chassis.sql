-- Ajout des colonnes pour les images et le numéro de châssis
-- dans la table avis_recherche

-- Ajouter une colonne pour stocker les chemins des images (format JSON)
ALTER TABLE `avis_recherche` 
ADD COLUMN `images` TEXT NULL COMMENT 'Chemins des images au format JSON' AFTER `niveau`;

-- Ajouter une colonne pour le numéro de châssis (pour les véhicules)
ALTER TABLE `avis_recherche` 
ADD COLUMN `numero_chassis` VARCHAR(100) NULL COMMENT 'Numéro de châssis du véhicule' AFTER `images`;

-- Créer un index sur le numéro de châssis pour les recherches
ALTER TABLE `avis_recherche`
ADD KEY `idx_numero_chassis` (`numero_chassis`);
