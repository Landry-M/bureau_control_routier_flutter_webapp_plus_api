-- ============================================
-- Migration: Ajout des colonnes images et numero_chassis 
-- à la table avis_recherche
-- Version compatible MySQL 5.x / MariaDB 10.x
-- Date: 2025-10-14
-- ============================================

-- IMPORTANT: Si les colonnes existent déjà, vous recevrez des erreurs.
-- C'est normal, continuez simplement avec le reste du script.

-- Ajouter la colonne 'images'
-- Stocke les chemins des images au format JSON
ALTER TABLE `avis_recherche` 
ADD COLUMN `images` TEXT NULL 
COMMENT 'Chemins des images au format JSON' 
AFTER `niveau`;

-- Ajouter la colonne 'numero_chassis'
-- Stocke le numéro de châssis du véhicule
ALTER TABLE `avis_recherche` 
ADD COLUMN `numero_chassis` VARCHAR(100) NULL 
COMMENT 'Numéro de châssis du véhicule' 
AFTER `images`;

-- Ajouter un index sur le numéro de châssis
ALTER TABLE `avis_recherche` 
ADD KEY `idx_numero_chassis` (`numero_chassis`);

-- ============================================
-- Vérification (optionnel)
-- ============================================

-- Afficher la structure de la table
-- DESCRIBE `avis_recherche`;

-- Afficher les index
-- SHOW INDEX FROM `avis_recherche`;
