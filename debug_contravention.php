<?php
/**
 * Script de débogage complet pour une contravention spécifique
 * Usage: debug_contravention.php?id=123
 */

require_once __DIR__ . '/api/config/database.php';

$cvId = isset($_GET['id']) ? (int)$_GET['id'] : 0;

if ($cvId <= 0) {
    echo "<h2>⚠️ Veuillez fournir un ID de contravention</h2>";
    echo "<p>Usage: <code>debug_contravention.php?id=123</code></p>";
    
    // Afficher les IDs disponibles
    try {
        $database = new Database();
        $db = $database->getConnection();
        $stmt = $db->query("SELECT id, type_dossier, created_at FROM contraventions ORDER BY created_at DESC LIMIT 10");
        $cvs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        if (!empty($cvs)) {
            echo "<h3>Contraventions récentes :</h3>";
            echo "<ul>";
            foreach ($cvs as $cv) {
                echo "<li><a href='?id=" . $cv['id'] . "'>Contravention #" . $cv['id'] . "</a> - " . 
                     htmlspecialchars($cv['type_dossier']) . " - " . $cv['created_at'] . "</li>";
            }
            echo "</ul>";
        }
    } catch (Exception $e) {
        echo "<p style='color: red;'>Erreur: " . htmlspecialchars($e->getMessage()) . "</p>";
    }
    exit;
}

try {
    $database = new Database();
    $db = $database->getConnection();
    
    // Récupérer la contravention
    $stmt = $db->prepare("SELECT * FROM contraventions WHERE id = :id");
    $stmt->bindParam(':id', $cvId);
    $stmt->execute();
    $cv = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$cv) {
        echo "<h2 style='color: red;'>❌ Contravention #$cvId introuvable</h2>";
        exit;
    }
    
    echo "<h2>🔍 Débogage Contravention #$cvId</h2>";
    echo "<p><a href='contravention_display.php?id=$cvId' target='_blank'>Voir le display →</a></p>";
    
    // Section 1: Statut de paiement
    echo "<div style='border: 2px solid #00509e; padding: 20px; margin: 20px 0; border-radius: 8px;'>";
    echo "<h3 style='color: #00509e;'>💰 Statut de paiement</h3>";
    
    $payedValue = $cv['payed'] ?? '';
    $payedType = gettype($payedValue);
    
    echo "<table border='1' cellpadding='8' style='border-collapse: collapse;'>";
    echo "<tr><th>Attribut</th><th>Valeur</th></tr>";
    echo "<tr><td><strong>Valeur brute</strong></td><td><code>" . htmlspecialchars(var_export($payedValue, true)) . "</code></td></tr>";
    echo "<tr><td><strong>Type PHP</strong></td><td><code>$payedType</code></td></tr>";
    echo "<tr><td><strong>Longueur</strong></td><td>" . strlen($payedValue) . "</td></tr>";
    echo "<tr><td><strong>Valeur === 'oui'</strong></td><td>" . ($payedValue === 'oui' ? '✅ OUI' : '❌ NON') . "</td></tr>";
    echo "<tr><td><strong>Valeur === '1'</strong></td><td>" . ($payedValue === '1' ? '✅ OUI' : '❌ NON') . "</td></tr>";
    echo "<tr><td><strong>Valeur === 1</strong></td><td>" . ($payedValue === 1 ? '✅ OUI' : '❌ NON') . "</td></tr>";
    
    // Test de la condition du display
    $displayCondition = ($cv['payed'] === 'oui' || $cv['payed'] === '1');
    echo "<tr style='background: " . ($displayCondition ? '#e8f4e8' : '#ffe8e8') . ";'>";
    echo "<td><strong>Condition display (payed === 'oui' || payed === '1')</strong></td>";
    echo "<td><strong>" . ($displayCondition ? '✅ PAYÉ' : '❌ NON PAYÉ') . "</strong></td>";
    echo "</tr>";
    echo "</table>";
    echo "</div>";
    
    // Section 2: Photos/Images
    echo "<div style='border: 2px solid #ff9800; padding: 20px; margin: 20px 0; border-radius: 8px;'>";
    echo "<h3 style='color: #ff9800;'>📸 Photos de la contravention</h3>";
    
    $photosValue = $cv['photos'] ?? '';
    $photosType = gettype($photosValue);
    $photosEmpty = empty($photosValue);
    
    echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>Attribut</th><th>Valeur</th></tr>";
    echo "<tr><td><strong>Colonne 'photos' vide</strong></td><td>" . ($photosEmpty ? '❌ OUI (vide)' : '✅ NON (contient des données)') . "</td></tr>";
    echo "<tr><td><strong>Type PHP</strong></td><td><code>$photosType</code></td></tr>";
    echo "<tr><td><strong>Longueur</strong></td><td>" . strlen($photosValue) . " caractères</td></tr>";
    echo "<tr><td><strong>Valeur brute</strong></td><td><code style='word-break: break-all;'>" . htmlspecialchars($photosValue) . "</code></td></tr>";
    echo "</table>";
    
    // Tester le parsing
    echo "<h4>🔧 Test de parsing des photos :</h4>";
    
    $images = [];
    if (!empty($cv['photos'])) {
        // Essayer JSON
        $imagesJson = json_decode($cv['photos'], true);
        if (is_array($imagesJson)) {
            $images = $imagesJson;
            echo "<p>✅ <strong>Format détecté :</strong> JSON</p>";
        } else {
            // Essayer virgule
            if (is_string($cv['photos']) && strpos($cv['photos'], ',') !== false) {
                $images = explode(',', $cv['photos']);
                $images = array_map('trim', $images);
                $images = array_filter($images);
                echo "<p>✅ <strong>Format détecté :</strong> Séparé par virgules</p>";
            } elseif (is_string($cv['photos']) && trim($cv['photos']) !== '') {
                $images = [trim($cv['photos'])];
                echo "<p>✅ <strong>Format détecté :</strong> Chaîne simple</p>";
            }
        }
    } else {
        echo "<p>❌ <strong>Aucune photo trouvée</strong> (colonne 'photos' est vide)</p>";
    }
    
    echo "<p><strong>Nombre d'images parsées :</strong> " . count($images) . "</p>";
    
    if (!empty($images)) {
        echo "<h4>URLs générées :</h4>";
        echo "<ol>";
        
        $baseUrl = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'];
        
        foreach ($images as $index => $image) {
            $imageUrl = trim($image);
            
            if (!preg_match('/^https?:\/\//', $imageUrl)) {
                $imageUrl = ltrim($imageUrl, '/');
                if (!preg_match('/^api\//', $imageUrl)) {
                    if (preg_match('/^uploads\//', $imageUrl)) {
                        $imageUrl = 'api/' . $imageUrl;
                    }
                }
                $fullUrl = $baseUrl . '/' . $imageUrl;
            } else {
                $fullUrl = $imageUrl;
            }
            
            echo "<li>";
            echo "<strong>Image " . ($index + 1) . " :</strong><br>";
            echo "Chemin brut: <code>" . htmlspecialchars($image) . "</code><br>";
            echo "URL complète: <code>" . htmlspecialchars($fullUrl) . "</code><br>";
            echo "<img src='$fullUrl' style='max-width: 300px; margin-top: 10px; border: 2px solid #ddd;' ";
            echo "onerror=\"this.style.border='2px solid red'; this.alt='❌ Image non accessible';\" ";
            echo "onload=\"this.style.border='2px solid green';\">";
            echo "</li><br>";
        }
        echo "</ol>";
    }
    
    echo "</div>";
    
    // Section 3: Toutes les données
    echo "<div style='border: 2px solid #666; padding: 20px; margin: 20px 0; border-radius: 8px;'>";
    echo "<h3>📋 Toutes les données de la contravention</h3>";
    echo "<pre style='background: #f5f5f5; padding: 15px; overflow-x: auto;'>";
    print_r($cv);
    echo "</pre>";
    echo "</div>";
    
} catch (Exception $e) {
    echo "<h2 style='color: red;'>❌ Erreur</h2>";
    echo "<p>" . htmlspecialchars($e->getMessage()) . "</p>";
}
?>
