-- Configuration MySQL pour éviter "MySQL server has gone away"
-- À exécuter sur le serveur MySQL

-- 1. Augmenter le timeout de connexion (5 minutes)
SET GLOBAL wait_timeout = 300;
SET GLOBAL interactive_timeout = 300;

-- 2. Augmenter la taille max des paquets (64 MB pour les uploads d'images)
SET GLOBAL max_allowed_packet = 67108864;

-- 3. Augmenter le timeout de lecture réseau (pour les opérations longues)
SET GLOBAL net_read_timeout = 120;
SET GLOBAL net_write_timeout = 120;

-- 4. Vérifier les valeurs configurées
SELECT 
    @@global.wait_timeout as wait_timeout,
    @@global.interactive_timeout as interactive_timeout,
    @@global.max_allowed_packet as max_allowed_packet,
    @@global.net_read_timeout as net_read_timeout,
    @@global.net_write_timeout as net_write_timeout;

-- Note : Ces paramètres sont perdus au redémarrage du serveur MySQL
-- Pour les rendre permanents, modifier le fichier my.cnf ou my.ini :
--
-- [mysqld]
-- wait_timeout = 300
-- interactive_timeout = 300
-- max_allowed_packet = 67108864
-- net_read_timeout = 120
-- net_write_timeout = 120
