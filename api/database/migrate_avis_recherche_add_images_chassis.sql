-- ============================================
-- Migration: Ajout des colonnes images et numero_chassis 
-- à la table avis_recherche
-- Date: 2025-10-14
-- ============================================

USE `control_routier`;

-- Vérifier et ajouter la colonne 'images'
-- Cette colonne stocke les chemins des images au format JSON
ALTER TABLE `avis_recherche` 
ADD COLUMN IF NOT EXISTS `images` TEXT NULL 
COMMENT 'Chemins des images au format JSON' 
AFTER `niveau`;

-- Vérifier et ajouter la colonne 'numero_chassis'
-- Cette colonne stocke le numéro de châssis du véhicule (pour les avis de recherche de véhicules)
ALTER TABLE `avis_recherche` 
ADD COLUMN IF NOT EXISTS `numero_chassis` VARCHAR(100) NULL 
COMMENT 'Numéro de châssis du véhicule' 
AFTER `images`;

-- Ajouter un index sur le numéro de châssis pour optimiser les recherches
-- Utiliser une procédure pour éviter les erreurs si l'index existe déjà
DROP PROCEDURE IF EXISTS AddIndexIfNotExists;

DELIMITER $$
CREATE PROCEDURE AddIndexIfNotExists()
BEGIN
    DECLARE index_exists INT DEFAULT 0;
    
    -- Vérifier si l'index existe déjà
    SELECT COUNT(1) INTO index_exists
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
    AND table_name = 'avis_recherche'
    AND index_name = 'idx_numero_chassis';
    
    -- Créer l'index s'il n'existe pas
    IF index_exists = 0 THEN
        ALTER TABLE `avis_recherche` 
        ADD KEY `idx_numero_chassis` (`numero_chassis`);
    END IF;
END$$
DELIMITER ;

-- Exécuter la procédure
CALL AddIndexIfNotExists();

-- Supprimer la procédure après utilisation
DROP PROCEDURE IF EXISTS AddIndexIfNotExists;

-- ============================================
-- Vérification de la migration
-- ============================================

-- Afficher la structure mise à jour de la table
DESCRIBE `avis_recherche`;

-- Afficher les index de la table
SHOW INDEX FROM `avis_recherche`;

-- ============================================
-- Migration terminée avec succès
-- ============================================
