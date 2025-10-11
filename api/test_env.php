<?php
// Test de la configuration d'environnement
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

try {
    // Test d'inclusion du fichier env.php
    require_once __DIR__ . '/config/env.php';
    
    $environment = Environment::getEnvironment();
    $config = Environment::getDatabaseConfig();
    
    echo json_encode([
        'status' => 'success',
        'message' => 'Configuration d\'environnement chargée avec succès',
        'environment' => $environment,
        'host_detected' => $_SERVER['HTTP_HOST'] ?? 'unknown',
        'config' => [
            'host' => $config['host'],
            'db_name' => $config['db_name'],
            'username' => $config['username'],
            'password_length' => strlen($config['password']),
            'charset' => $config['charset']
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Erreur lors du chargement de la configuration',
        'error' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}
?>
