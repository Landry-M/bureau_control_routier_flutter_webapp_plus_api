-- Ajouter les colonnes latitude et longitude à la table accidents

ALTER TABLE `accidents` 
ADD COLUMN `latitude` DECIMAL(10, 8) DEFAULT NULL AFTER `lieu`,
ADD COLUMN `longitude` DECIMAL(11, 8) DEFAULT NULL AFTER `latitude`;

-- Ajouter un index pour optimiser les requêtes géospatiales
CREATE INDEX `idx_accidents_location` ON `accidents` (`latitude`, `longitude`);
