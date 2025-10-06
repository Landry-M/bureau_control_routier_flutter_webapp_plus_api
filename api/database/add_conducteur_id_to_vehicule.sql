-- Script pour ajouter la colonne conducteur_id à la table vehicule_plaque
-- pour lier les véhicules aux conducteurs

ALTER TABLE `vehicule_plaque` 
ADD COLUMN `conducteur_id` bigint(20) DEFAULT NULL AFTER `updated_at`,
ADD COLUMN `proprietaire` varchar(200) DEFAULT NULL AFTER `conducteur_id`;

-- Ajouter une clé étrangère pour référencer la table conducteur_vehicule
ALTER TABLE `vehicule_plaque` 
ADD CONSTRAINT `fk_vehicule_conducteur` 
FOREIGN KEY (`conducteur_id`) REFERENCES `conducteur_vehicule`(`id`) 
ON DELETE SET NULL ON UPDATE CASCADE;

-- Ajouter un index pour améliorer les performances des requêtes
CREATE INDEX `idx_vehicule_conducteur` ON `vehicule_plaque`(`conducteur_id`);
