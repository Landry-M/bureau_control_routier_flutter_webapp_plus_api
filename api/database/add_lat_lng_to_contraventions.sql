-- Migration pour ajouter les coordonnées géographiques à la table contraventions
-- Date: 2025-10-08

USE control_routier;

-- Ajouter les colonnes latitude et longitude pour la localisation de l'infraction
ALTER TABLE contraventions 
ADD COLUMN latitude DECIMAL(10, 8) DEFAULT NULL COMMENT 'Latitude de l\'endroit de l\'infraction',
ADD COLUMN longitude DECIMAL(11, 8) DEFAULT NULL COMMENT 'Longitude de l\'endroit de l\'infraction';

-- Vérification de la modification
DESCRIBE contraventions;
