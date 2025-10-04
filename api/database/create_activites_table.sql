-- Table pour enregistrer les activités des utilisateurs
CREATE TABLE IF NOT EXISTS activites (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    action VARCHAR(255) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
);

-- Ajouter quelques exemples d'activités pour test
INSERT INTO activites (username, action, details, ip_address, created_at) VALUES
('admin', 'Connexion', '{"user_id": 1, "role": "admin", "first_connection": false}', '127.0.0.1', NOW()),
('police001', 'Connexion', '{"user_id": 2, "role": "agent", "first_connection": true}', '127.0.0.1', NOW() - INTERVAL 1 HOUR),
('super', 'Création d\'agent', '{"new_user_id": 3, "created_by": "super", "role": "agent", "username": "Nouvel Agent"}', '127.0.0.1', NOW() - INTERVAL 2 HOUR),
('landry', 'Première connexion - Changement de mot de passe', '{"user_id": 4, "action": "password_change_first_connection"}', '127.0.0.1', NOW() - INTERVAL 3 HOUR),
('system', 'Consultation du rapport d\'activités', '{"filters": {"limit": 100, "offset": 0}, "results_count": 15}', '127.0.0.1', NOW() - INTERVAL 30 MINUTE);
