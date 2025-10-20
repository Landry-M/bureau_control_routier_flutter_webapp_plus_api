-- Ajout de la colonne pdf_path à la table avis_recherche
-- pour stocker le chemin du PDF généré

ALTER TABLE `avis_recherche` 
ADD COLUMN IF NOT EXISTS `pdf_path` TEXT NULL 
COMMENT 'Chemin du PDF généré pour l''avis de recherche' 
AFTER `numero_chassis`;
