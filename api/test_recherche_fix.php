<?php
/**
 * Script de test pour vérifier la correction de la recherche PDO
 * Date: 14 octobre 2025
 */

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/controllers/ParticulierController.php';

echo "=== TEST DE LA RECHERCHE CORRIGÉE ===\n\n";

// Test 1: Recherche de particuliers
echo "Test 1: Recherche de particuliers\n";
echo "-----------------------------------\n";
try {
    $particulierController = new ParticulierController();
    
    // Test avec un terme de recherche
    $result = $particulierController->getAll(1, 10, 'Ka');
    
    if ($result['success']) {
        echo "✅ Recherche réussie\n";
        echo "   Résultats trouvés: " . count($result['data']) . "\n";
        echo "   Total dans la base: " . $result['pagination']['total'] . "\n";
        
        if (count($result['data']) > 0) {
            echo "   Premier résultat: " . $result['data'][0]['nom'] . "\n";
        }
    } else {
        echo "❌ Erreur: " . $result['message'] . "\n";
    }
} catch (Exception $e) {
    echo "❌ Exception: " . $e->getMessage() . "\n";
}

echo "\n";

// Test 2: Recherche de véhicules via l'API
echo "Test 2: Recherche de véhicules\n";
echo "--------------------------------\n";
try {
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        throw new Exception('Connexion à la base de données échouée');
    }
    
    $search = 'CD';
    $whereClause = 'WHERE plaque LIKE :search1 OR marque LIKE :search2 OR modele LIKE :search3 OR proprietaire LIKE :search4';
    $searchParam = '%' . $search . '%';
    $params = [
        ':search1' => $searchParam,
        ':search2' => $searchParam,
        ':search3' => $searchParam,
        ':search4' => $searchParam
    ];
    
    $countStmt = $db->prepare("SELECT COUNT(*) as total FROM vehicule_plaque $whereClause");
    foreach ($params as $key => $value) {
        $countStmt->bindValue($key, $value);
    }
    $countStmt->execute();
    $totalCount = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    $stmt = $db->prepare("SELECT * FROM vehicule_plaque $whereClause LIMIT 10");
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->execute();
    $vehicules = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "✅ Recherche réussie\n";
    echo "   Résultats trouvés: " . count($vehicules) . "\n";
    echo "   Total dans la base: " . $totalCount . "\n";
    
    if (count($vehicules) > 0) {
        echo "   Premier résultat: " . $vehicules[0]['plaque'] . " - " . $vehicules[0]['marque'] . "\n";
    }
    
} catch (Exception $e) {
    echo "❌ Exception: " . $e->getMessage() . "\n";
}

echo "\n";

// Test 3: Test avec recherche vide
echo "Test 3: Recherche avec chaîne vide\n";
echo "-----------------------------------\n";
try {
    $particulierController = new ParticulierController();
    $result = $particulierController->getAll(1, 5, '');
    
    if ($result['success']) {
        echo "✅ Recherche sans filtre réussie\n";
        echo "   Total de particuliers: " . $result['pagination']['total'] . "\n";
        echo "   Résultats retournés: " . count($result['data']) . "\n";
    } else {
        echo "❌ Erreur: " . $result['message'] . "\n";
    }
} catch (Exception $e) {
    echo "❌ Exception: " . $e->getMessage() . "\n";
}

echo "\n=== FIN DES TESTS ===\n";
?>
