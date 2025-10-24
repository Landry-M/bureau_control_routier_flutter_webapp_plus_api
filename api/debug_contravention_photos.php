<?php
// Script de debug pour vérifier les photos des contraventions

require_once __DIR__ . '/config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    // Récupérer les 5 dernières contraventions
    $stmt = $db->prepare("
        SELECT id, dossier_id, type_dossier, type_infraction, photos, created_at
        FROM contraventions
        ORDER BY created_at DESC
        LIMIT 5
    ");
    $stmt->execute();
    $contraventions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<h2>🔍 Debug Contraventions - Photos</h2>";
    echo "<p>Total trouvées: " . count($contraventions) . "</p>";
    echo "<hr>";
    
    foreach ($contraventions as $cv) {
        echo "<div style='background: #f5f5f5; padding: 15px; margin: 10px 0; border-left: 4px solid #00509e;'>";
        echo "<h3>Contravention #" . $cv['id'] . "</h3>";
        echo "<p><strong>Type:</strong> " . $cv['type_dossier'] . "</p>";
        echo "<p><strong>Infraction:</strong> " . $cv['type_infraction'] . "</p>";
        echo "<p><strong>Date:</strong> " . $cv['created_at'] . "</p>";
        
        echo "<h4>Colonne 'photos' (brute):</h4>";
        echo "<pre style='background: #fff; padding: 10px; border: 1px solid #ddd;'>";
        echo htmlspecialchars($cv['photos'] ?? 'NULL');
        echo "</pre>";
        
        // Essayer de parser
        if (!empty($cv['photos'])) {
            $images = [];
            
            // Test JSON
            $imagesJson = json_decode($cv['photos'], true);
            if (is_array($imagesJson)) {
                $images = $imagesJson;
                echo "<p>✅ <strong>Format:</strong> JSON array</p>";
            } 
            // Test virgule
            elseif (strpos($cv['photos'], ',') !== false) {
                $images = explode(',', $cv['photos']);
                $images = array_map('trim', $images);
                $images = array_filter($images);
                echo "<p>✅ <strong>Format:</strong> Chaîne séparée par virgules</p>";
            }
            // Chaîne simple
            else {
                $images = [trim($cv['photos'])];
                echo "<p>✅ <strong>Format:</strong> Chaîne simple</p>";
            }
            
            echo "<p><strong>Nombre d'images parsées:</strong> " . count($images) . "</p>";
            
            if (!empty($images)) {
                echo "<h4>Images:</h4>";
                echo "<ul>";
                foreach ($images as $idx => $img) {
                    echo "<li>";
                    echo "<strong>Image " . ($idx + 1) . ":</strong> ";
                    echo "<code>" . htmlspecialchars($img) . "</code>";
                    
                    // Construire l'URL comme le fait contravention_display.php
                    $baseUrl = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'];
                    $imageUrl = ltrim($img, '/');
                    if (preg_match('/^uploads\//', $imageUrl)) {
                        $imageUrl = 'api/' . $imageUrl;
                    }
                    $fullUrl = $baseUrl . '/' . $imageUrl;
                    
                    echo "<br>→ URL: <code>" . htmlspecialchars($fullUrl) . "</code>";
                    
                    // Vérifier si le fichier existe
                    $localPath = __DIR__ . '/../' . $imageUrl;
                    if (file_exists($localPath)) {
                        echo " <span style='color: green;'>✅ Fichier existe</span>";
                        echo "<br>→ <img src='" . htmlspecialchars($fullUrl) . "' style='max-width: 200px; max-height: 150px; margin-top: 5px;' onerror=\"this.style.display='none'; this.nextSibling.style.display='inline';\">";
                        echo "<span style='display:none; color: red;'>❌ Erreur de chargement</span>";
                    } else {
                        echo " <span style='color: red;'>❌ Fichier n'existe pas</span>";
                        echo "<br>→ Chemin local: <code>" . htmlspecialchars($localPath) . "</code>";
                    }
                    echo "</li>";
                }
                echo "</ul>";
            }
        } else {
            echo "<p>⚠️ Aucune photo enregistrée</p>";
        }
        
        echo "</div>";
    }
    
} catch (Exception $e) {
    echo "<div style='color: red; padding: 20px; background: #ffe6e6;'>";
    echo "<h3>❌ Erreur</h3>";
    echo "<p>" . htmlspecialchars($e->getMessage()) . "</p>";
    echo "</div>";
}
?>
