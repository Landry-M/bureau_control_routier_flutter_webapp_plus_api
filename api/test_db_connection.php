<?php
// Script de test de connexion à la base de données - Version simplifiée
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

try {
    // Test 1: Chargement de la configuration
    require_once __DIR__ . '/config/env.php';
    
    $environment = Environment::getEnvironment();
    $config = Environment::getDatabaseConfig();
    
    // Test 2: Connexion PDO directe
    $dsn = "mysql:host=" . $config['host'] . ";dbname=" . $config['db_name'] . ";charset=" . $config['charset'];
    $pdo = new PDO($dsn, $config['username'], $config['password']);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Test 3: Requête simple
    $stmt = $pdo->prepare("SELECT 1 as test, NOW() as current_time");
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'status' => 'success',
        'message' => 'Connexion à la base de données réussie',
        'environment' => $environment,
        'config' => [
            'host' => $config['host'],
            'db_name' => $config['db_name'],
            'username' => $config['username'],
            'charset' => $config['charset']
        ],
        'test_query' => $result
    ]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'type' => 'database_error',
        'message' => 'Erreur de connexion à la base de données',
        'error' => $e->getMessage(),
        'code' => $e->getCode()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'type' => 'general_error',
        'message' => 'Erreur générale',
        'error' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}
?>
