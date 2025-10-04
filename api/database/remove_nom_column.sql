-- Script pour supprimer la colonne 'nom' de la table users
-- Seule la colonne 'username' sera utilisée pour stocker le nom complet

-- Vérifier la structure actuelle
-- DESCRIBE users;

-- Supprimer la colonne 'nom' si elle existe
ALTER TABLE users DROP COLUMN IF EXISTS nom;

-- Vérifier la nouvelle structure
-- DESCRIBE users;

-- La table users aura maintenant cette structure simplifiée :
/*
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    matricule VARCHAR(100) UNIQUE NOT NULL,
    username VARCHAR(255) NOT NULL,  -- ← Nom complet stocké ici
    prenom VARCHAR(255),
    email VARCHAR(255),
    telephone VARCHAR(20),
    role VARCHAR(50) DEFAULT 'agent',
    password VARCHAR(255) NOT NULL,
    statut VARCHAR(20) DEFAULT 'actif',
    first_connection VARCHAR(10) DEFAULT 'true',
    login_schedule TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
*/
