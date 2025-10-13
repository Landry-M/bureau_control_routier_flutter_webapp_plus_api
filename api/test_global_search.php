<?php
/**
 * Test de la recherche globale pour les véhicules
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain; charset=UTF-8');

echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║        TEST RECHERCHE GLOBALE - VÉHICULES                 ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/controllers/GlobalSearchController.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        throw new Exception('Connexion DB échouée');
    }
    
    echo "✅ Connexion DB OK\n\n";
    
    // 1. Vérifier la table vehicule_plaque
    echo "═══════════════════════════════════════════════════════════\n";
    echo "1️⃣  VÉRIFICATION TABLE vehicule_plaque\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $count = $db->query("SELECT COUNT(*) FROM vehicule_plaque")->fetchColumn();
    echo "Nombre de véhicules : $count\n\n";
    
    if ($count == 0) {
        echo "❌ Aucun véhicule dans la table vehicule_plaque\n";
        echo "   Créez d'abord des véhicules pour tester\n\n";
        exit(1);
    }
    
    // Lister quelques véhicules
    $vehicules = $db->query("
        SELECT id, plaque, marque, modele, couleur 
        FROM vehicule_plaque 
        ORDER BY created_at DESC 
        LIMIT 5
    ")->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Exemples de véhicules:\n";
    foreach ($vehicules as $v) {
        echo "  • {$v['plaque']} - {$v['marque']} {$v['modele']} ({$v['couleur']})\n";
    }
    echo "\n";
    
    // 2. Test recherche SQL directe
    echo "═══════════════════════════════════════════════════════════\n";
    echo "2️⃣  TEST RECHERCHE SQL DIRECTE\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $testPlaque = $vehicules[0]['plaque'];
    $searchTerm = '%' . $testPlaque . '%';
    
    echo "Test avec plaque: $testPlaque\n";
    
    $stmt = $db->prepare("
        SELECT id, plaque, marque, modele, couleur 
        FROM vehicule_plaque 
        WHERE plaque LIKE :search
    ");
    $stmt->bindValue(':search', $searchTerm);
    $stmt->execute();
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($results) > 0) {
        echo "✅ Recherche SQL fonctionne - " . count($results) . " résultat(s)\n";
        foreach ($results as $r) {
            echo "  • {$r['plaque']} - {$r['marque']} {$r['modele']}\n";
        }
    } else {
        echo "❌ Aucun résultat avec la recherche SQL\n";
    }
    echo "\n";
    
    // 3. Test avec GlobalSearchController
    echo "═══════════════════════════════════════════════════════════\n";
    echo "3️⃣  TEST GlobalSearchController\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $controller = new GlobalSearchController();
    $result = $controller->globalSearch($testPlaque);
    
    if (!$result['success']) {
        echo "❌ Erreur GlobalSearchController\n";
        echo "Message: {$result['message']}\n\n";
        exit(1);
    }
    
    echo "✅ GlobalSearchController fonctionne\n";
    echo "Nombre total de résultats: {$result['total']}\n\n";
    
    // Filtrer les véhicules
    $vehiculeResults = array_filter($result['data'], function($item) {
        return $item['type'] === 'vehicule';
    });
    
    echo "Résultats de type 'vehicule': " . count($vehiculeResults) . "\n";
    
    if (count($vehiculeResults) > 0) {
        echo "✅ Véhicules trouvés:\n";
        foreach ($vehiculeResults as $v) {
            echo "  • {$v['title']}\n";
            echo "    Sous-titre: {$v['subtitle']}\n";
        }
    } else {
        echo "❌ Aucun véhicule trouvé via GlobalSearchController\n";
        echo "\n🔍 Tous les résultats retournés:\n";
        foreach ($result['data'] as $item) {
            echo "  • Type: {$item['type']} | {$item['title']}\n";
        }
    }
    echo "\n";
    
    // 4. Test de plusieurs termes de recherche
    echo "═══════════════════════════════════════════════════════════\n";
    echo "4️⃣  TEST AVEC DIFFÉRENTS TERMES\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $testTerms = [
        $vehicules[0]['plaque'] ?? '',
        substr($vehicules[0]['plaque'] ?? '', 0, 3), // 3 premiers caractères
        $vehicules[0]['marque'] ?? '',
        $vehicules[0]['couleur'] ?? ''
    ];
    
    foreach ($testTerms as $term) {
        if (empty($term)) continue;
        
        echo "Recherche: '$term'\n";
        $result = $controller->globalSearch($term);
        
        if ($result['success']) {
            $vehiculeCount = count(array_filter($result['data'], function($item) {
                return $item['type'] === 'vehicule';
            }));
            echo "  → Total: {$result['total']} | Véhicules: $vehiculeCount\n";
        } else {
            echo "  → Erreur: {$result['message']}\n";
        }
    }
    echo "\n";
    
    // 5. Test API endpoint
    echo "═══════════════════════════════════════════════════════════\n";
    echo "5️⃣  TEST API ENDPOINT\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    echo "URL de test (dans navigateur ou Postman):\n";
    echo "  https://controls.heaventech.net/api/search/global?q=" . urlencode($testPlaque) . "\n\n";
    
    echo "Commande curl:\n";
    echo "  curl 'https://controls.heaventech.net/api/search/global?q=" . urlencode($testPlaque) . "'\n\n";
    
    // 6. Diagnostic
    echo "═══════════════════════════════════════════════════════════\n";
    echo "📊 DIAGNOSTIC\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    if (count($vehiculeResults) > 0) {
        echo "✅ TOUT FONCTIONNE CORRECTEMENT\n\n";
        echo "La recherche globale trouve bien les véhicules.\n";
        echo "Si le problème persiste dans Flutter:\n";
        echo "  1. Vérifier l'URL de l'API dans ApiConfig\n";
        echo "  2. Vérifier le parsing JSON de la réponse\n";
        echo "  3. Vérifier les filtres côté Flutter\n";
        echo "  4. Consulter les logs de l'app mobile\n\n";
    } else {
        echo "⚠️  PROBLÈME DÉTECTÉ\n\n";
        echo "Causes possibles:\n";
        echo "  1. La méthode searchVehicles() ne retourne rien\n";
        echo "  2. Problème de bind des paramètres\n";
        echo "  3. Erreur silencieuse dans le contrôleur\n\n";
        
        echo "Solutions:\n";
        echo "  1. Vérifier les logs PHP pour les erreurs\n";
        echo "  2. Tester la requête SQL manuellement\n";
        echo "  3. Vérifier que la connexion DB est maintenue\n\n";
    }
    
    // 7. Structure de réponse attendue
    echo "═══════════════════════════════════════════════════════════\n";
    echo "📋 STRUCTURE RÉPONSE JSON ATTENDUE\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    echo "{\n";
    echo "  \"success\": true,\n";
    echo "  \"total\": 1,\n";
    echo "  \"query\": \"$testPlaque\",\n";
    echo "  \"data\": [\n";
    echo "    {\n";
    echo "      \"id\": \"123\",\n";
    echo "      \"type\": \"vehicule\",\n";
    echo "      \"type_label\": \"Véhicule\",\n";
    echo "      \"title\": \"ABC-123 - Toyota Corolla\",\n";
    echo "      \"subtitle\": \"Couleur: Blanche | Année: 2020\",\n";
    echo "      \"created_at\": \"2025-10-13 14:00:00\",\n";
    echo "      \"data\": { ... }\n";
    echo "    }\n";
    echo "  ]\n";
    echo "}\n\n";
    
} catch (Exception $e) {
    echo "\n❌ ERREUR FATALE\n\n";
    echo "Message: " . $e->getMessage() . "\n";
    echo "Fichier: " . $e->getFile() . "\n";
    echo "Ligne: " . $e->getLine() . "\n";
    echo "Trace:\n" . $e->getTraceAsString() . "\n";
}

echo "\n⚠️  SUPPRIMEZ ce fichier après les tests\n";
?>
