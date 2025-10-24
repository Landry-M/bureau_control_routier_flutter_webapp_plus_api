<?php
/**
 * Script de vérification des photos de contraventions
 */

require_once __DIR__ . '/api/config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    echo "<h2>Vérification des photos de contraventions</h2>";
    
    // Récupérer les contraventions récentes avec leurs photos
    $stmt = $db->query("SELECT id, dossier_id, type_dossier, photos, created_at 
                        FROM contraventions 
                        ORDER BY created_at DESC 
                        LIMIT 10");
    
    $contraventions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<p><strong>Nombre de contraventions trouvées :</strong> " . count($contraventions) . "</p>";
    
    if (empty($contraventions)) {
        echo "<p style='color: orange;'>Aucune contravention trouvée dans la base de données.</p>";
        exit;
    }
    
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr style='background: #00509e; color: white;'>
            <th>ID</th>
            <th>Type dossier</th>
            <th>Dossier ID</th>
            <th>Photos (brut)</th>
            <th>Photos (décodé)</th>
            <th>Date création</th>
          </tr>";
    
    foreach ($contraventions as $cv) {
        $photosRaw = $cv['photos'] ?? '';
        $photosDecoded = '';
        
        if (!empty($photosRaw)) {
            // Essayer de décoder comme JSON
            $jsonDecoded = json_decode($photosRaw, true);
            if (is_array($jsonDecoded)) {
                $photosDecoded = "JSON: " . implode(', ', $jsonDecoded);
            } else {
                // Si ce n'est pas du JSON, peut-être séparé par des virgules
                if (strpos($photosRaw, ',') !== false) {
                    $photosDecoded = "Virgule: " . $photosRaw;
                } else {
                    $photosDecoded = "Simple: " . $photosRaw;
                }
            }
        } else {
            $photosDecoded = "<span style='color: red;'>Vide</span>";
        }
        
        $hasPhotos = !empty($photosRaw);
        $rowColor = $hasPhotos ? '#e8f4e8' : '#fff3e0';
        
        echo "<tr style='background: $rowColor;'>";
        echo "<td><strong>" . htmlspecialchars($cv['id']) . "</strong></td>";
        echo "<td>" . htmlspecialchars($cv['type_dossier']) . "</td>";
        echo "<td>" . htmlspecialchars($cv['dossier_id']) . "</td>";
        echo "<td><code style='font-size: 11px;'>" . htmlspecialchars(substr($photosRaw, 0, 100)) . "</code></td>";
        echo "<td>" . $photosDecoded . "</td>";
        echo "<td>" . htmlspecialchars($cv['created_at']) . "</td>";
        echo "</tr>";
    }
    
    echo "</table>";
    
    echo "<br><h3>Légende</h3>";
    echo "<ul>";
    echo "<li><strong style='background: #e8f4e8; padding: 2px 8px;'>Vert clair</strong> : Contravention avec photos</li>";
    echo "<li><strong style='background: #fff3e0; padding: 2px 8px;'>Orange clair</strong> : Contravention sans photos</li>";
    echo "</ul>";
    
    // Statistiques
    $withPhotos = 0;
    $withoutPhotos = 0;
    foreach ($contraventions as $cv) {
        if (!empty($cv['photos'])) {
            $withPhotos++;
        } else {
            $withoutPhotos++;
        }
    }
    
    echo "<h3>Statistiques (10 dernières contraventions)</h3>";
    echo "<ul>";
    echo "<li><strong>Avec photos :</strong> $withPhotos</li>";
    echo "<li><strong>Sans photos :</strong> $withoutPhotos</li>";
    echo "</ul>";
    
} catch (Exception $e) {
    echo "<p style='color: red;'><strong>Erreur :</strong> " . htmlspecialchars($e->getMessage()) . "</p>";
}
?>
