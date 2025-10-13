<?php
// Configuration d'environnement
class Environment {
    
    /**
     * Détecte l'environnement actuel basé sur le domaine
     */
    public static function getEnvironment() {
        $host = $_SERVER['HTTP_HOST'] ?? $_SERVER['SERVER_NAME'] ?? 'localhost';
        
        if (strpos($host, 'heaventech.net') !== false) {
            return 'production';
        } elseif (strpos($host, 'localhost') !== false || strpos($host, '127.0.0.1') !== false) {
            return 'development';
        } else {
            return 'development'; // Par défaut
        }
    }
    
    /**
     * Retourne la configuration de base de données selon l'environnement
     */
    public static function getDatabaseConfig() {
        $env = self::getEnvironment();
        
        switch ($env) {
            case 'production':
                return [
                    'host' => 'localhost',
                    'db_name' => 'ngla4195_control_routier',     // ✅ Configuré pour controls.heaventech.net
                    'username' => 'ngla4195_control_routier',    // ✅ Utilisateur MySQL de production
                    'password' => 'piPfIC&wSOU&',                // ✅ Mot de passe de production
                    'charset' => 'utf8mb4'
                ];
                
            case 'development':
            default:
                return [
                    'host' => 'localhost',
                    'db_name' => 'control_routier',
                    'username' => 'root',
                    'password' => '',
                    'charset' => 'utf8'
                ];
        }
    }
    
    /**
     * Active/désactive le mode debug selon l'environnement
     */
    public static function isDebugMode() {
        return self::getEnvironment() === 'development';
    }
    
    /**
     * Retourne l'URL de base selon l'environnement
     */
    public static function getBaseUrl() {
        $env = self::getEnvironment();
        
        switch ($env) {
            case 'production':
                return 'https://controls.heaventech.net';
                
            case 'development':
            default:
                return 'http://localhost:8000';
        }
    }
}
?>
