-- Migration pour rendre le champ GSM optionnel dans la table entreprises
-- Date: 2025-10-04

USE control_routier;

-- Modifier la colonne gsm pour permettre les valeurs NULL
ALTER TABLE entreprises 
MODIFY COLUMN gsm varchar(30) DEFAULT NULL;

-- Vérification de la modification
DESCRIBE entreprises;
