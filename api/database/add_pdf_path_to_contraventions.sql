-- Migration pour ajouter le champ pdf_path à la table contraventions
-- Date: 2025-10-08

USE control_routier;

-- Ajouter la colonne pdf_path pour stocker le chemin du PDF généré
ALTER TABLE contraventions 
ADD COLUMN pdf_path VARCHAR(500) DEFAULT NULL COMMENT 'Chemin vers le PDF généré de la contravention';

-- Vérification de la modification
DESCRIBE contraventions;
