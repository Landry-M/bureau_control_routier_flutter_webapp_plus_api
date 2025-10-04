-- Script pour mettre à jour la table users avec toutes les colonnes nécessaires

-- Vérifier et ajouter les colonnes manquantes si elles n'existent pas
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS matricule VARCHAR(100) UNIQUE,
ADD COLUMN IF NOT EXISTS nom VARCHAR(255),
ADD COLUMN IF NOT EXISTS prenom VARCHAR(255),
ADD COLUMN IF NOT EXISTS email VARCHAR(255),
ADD COLUMN IF NOT EXISTS telephone VARCHAR(20),
ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'agent',
ADD COLUMN IF NOT EXISTS password VARCHAR(255),
ADD COLUMN IF NOT EXISTS statut VARCHAR(20) DEFAULT 'actif',
ADD COLUMN IF NOT EXISTS first_connection VARCHAR(10) DEFAULT 'true',
ADD COLUMN IF NOT EXISTS login_schedule TEXT,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- Ajouter des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_users_matricule ON users(matricule);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_statut ON users(statut);

-- Exemple de structure complète de la table users
/*
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    matricule VARCHAR(100) UNIQUE NOT NULL,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255),
    email VARCHAR(255),
    telephone VARCHAR(20),
    role VARCHAR(50) DEFAULT 'agent',
    password VARCHAR(255) NOT NULL,
    statut VARCHAR(20) DEFAULT 'actif',
    first_connection VARCHAR(10) DEFAULT 'true',
    login_schedule TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_matricule (matricule),
    INDEX idx_role (role),
    INDEX idx_statut (statut)
);
*/
