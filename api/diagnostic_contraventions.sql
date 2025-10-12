-- Script de diagnostic pour la table contraventions
-- Ce script vérifie la structure de la table et les données

-- 1. Vérifier la structure de la table
DESCRIBE contraventions;

-- 2. Vérifier si les colonnes lieu et amende existent
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'contraventions'
    AND COLUMN_NAME IN ('lieu', 'amende', 'latitude', 'longitude')
ORDER BY COLUMN_NAME;

-- 3. Compter les contraventions avec lieu vide ou NULL
SELECT 
    COUNT(*) as total_contraventions,
    SUM(CASE WHEN lieu IS NULL OR lieu = '' THEN 1 ELSE 0 END) as lieu_vide,
    SUM(CASE WHEN amende IS NULL OR amende = '' OR amende = '0' THEN 1 ELSE 0 END) as amende_vide
FROM contraventions;

-- 4. Afficher quelques exemples de contraventions avec leurs données
SELECT 
    id,
    type_dossier,
    date_infraction,
    lieu,
    type_infraction,
    amende,
    payed,
    created_at
FROM contraventions
ORDER BY created_at DESC
LIMIT 10;

-- 5. Si les colonnes n'existent pas, les créer (décommentez si nécessaire)
-- ALTER TABLE contraventions ADD COLUMN lieu VARCHAR(500) DEFAULT NULL;
-- ALTER TABLE contraventions ADD COLUMN amende DECIMAL(15,2) DEFAULT 0;

-- 6. Si les colonnes existent mais ont le mauvais type, les modifier
-- ALTER TABLE contraventions MODIFY COLUMN lieu VARCHAR(500);
-- ALTER TABLE contraventions MODIFY COLUMN amende DECIMAL(15,2);
