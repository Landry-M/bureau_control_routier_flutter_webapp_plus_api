<?php
/**
 * Script de vérification de la configuration des images d'avis de recherche
 */

require_once __DIR__ . '/config/database.php';

echo "<h2>Vérification de la configuration des images d'avis de recherche</h2>";

try {
    $database = new Database();
    $pdo = $database->getConnection();
    
    echo "<h3>1. Vérification de la colonne 'images' dans la table avis_recherche</h3>";
    
    // Vérifier si la colonne images existe
    $stmt = $pdo->query("SHOW COLUMNS FROM avis_recherche LIKE 'images'");
    $columnExists = $stmt->fetch();
    
    if ($columnExists) {
        echo "✅ La colonne 'images' existe dans la table avis_recherche<br>";
        echo "Type: " . $columnExists['Type'] . "<br>";
    } else {
        echo "❌ La colonne 'images' n'existe PAS dans la table avis_recherche<br>";
        echo "<strong>Solution :</strong> Exécutez le fichier SQL suivant :<br>";
        echo "<code>/api/database/add_avis_recherche_images_chassis.sql</code><br><br>";
        echo "<textarea style='width:100%;height:150px;'>";
        echo file_get_contents(__DIR__ . '/database/add_avis_recherche_images_chassis.sql');
        echo "</textarea><br>";
    }
    
    // Vérifier si la colonne numero_chassis existe
    echo "<h3>2. Vérification de la colonne 'numero_chassis'</h3>";
    $stmt = $pdo->query("SHOW COLUMNS FROM avis_recherche LIKE 'numero_chassis'");
    $chassisExists = $stmt->fetch();
    
    if ($chassisExists) {
        echo "✅ La colonne 'numero_chassis' existe<br>";
    } else {
        echo "❌ La colonne 'numero_chassis' n'existe PAS<br>";
    }
    
    // Vérifier le dossier d'upload
    echo "<h3>3. Vérification du dossier d'upload</h3>";
    $uploadDir = __DIR__ . '/../uploads/avis_recherche/';
    
    if (is_dir($uploadDir)) {
        echo "✅ Le dossier existe: $uploadDir<br>";
        if (is_writable($uploadDir)) {
            echo "✅ Le dossier est accessible en écriture<br>";
        } else {
            echo "⚠️ Le dossier n'est PAS accessible en écriture<br>";
            echo "<strong>Solution :</strong> Exécutez: <code>chmod 777 $uploadDir</code><br>";
        }
    } else {
        echo "❌ Le dossier n'existe PAS: $uploadDir<br>";
        echo "<strong>Création du dossier...</strong><br>";
        if (mkdir($uploadDir, 0777, true)) {
            echo "✅ Dossier créé avec succès<br>";
        } else {
            echo "❌ Impossible de créer le dossier<br>";
        }
    }
    
    // Tester les avis existants avec images
    echo "<h3>4. Avis de recherche existants avec images</h3>";
    $stmt = $pdo->query("SELECT id, images, created_at FROM avis_recherche WHERE images IS NOT NULL AND images != '' ORDER BY created_at DESC LIMIT 5");
    $avisWithImages = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (!empty($avisWithImages)) {
        echo "<p>Trouvé " . count($avisWithImages) . " avis avec images :</p>";
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>ID</th><th>Images JSON</th><th>Décodage</th><th>Date</th></tr>";
        foreach ($avisWithImages as $avis) {
            echo "<tr>";
            echo "<td>" . $avis['id'] . "</td>";
            echo "<td><small>" . htmlspecialchars(substr($avis['images'], 0, 100)) . "...</small></td>";
            $decoded = json_decode($avis['images'], true);
            echo "<td>" . (is_array($decoded) ? "✅ Array (" . count($decoded) . " images)" : "❌ Erreur") . "</td>";
            echo "<td>" . $avis['created_at'] . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p>ℹ️ Aucun avis de recherche avec images trouvé dans la base de données</p>";
    }
    
    // Total des avis
    echo "<h3>5. Statistiques</h3>";
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM avis_recherche");
    $total = $stmt->fetch()['total'];
    
    $stmt = $pdo->query("SELECT COUNT(*) as avec_images FROM avis_recherche WHERE images IS NOT NULL AND images != ''");
    $avecImages = $stmt->fetch()['avec_images'];
    
    echo "<p>Total d'avis de recherche : <strong>$total</strong></p>";
    echo "<p>Avec images : <strong>$avecImages</strong></p>";
    echo "<p>Sans images : <strong>" . ($total - $avecImages) . "</strong></p>";
    
} catch (Exception $e) {
    echo "<p style='color:red;'>Erreur : " . htmlspecialchars($e->getMessage()) . "</p>";
}
?>
