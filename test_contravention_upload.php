<?php
/**
 * Script de test pour l'upload des photos de contraventions
 * Ce script simule un upload multipart comme le ferait Flutter
 */

echo "<h2>🧪 Test d'upload de photos de contravention</h2>";

// Vérifier que le dossier uploads/contraventions existe
$uploadDir = __DIR__ . '/api/uploads/contraventions/';
echo "<h3>1. Vérification du dossier d'upload</h3>";

if (!is_dir($uploadDir)) {
    echo "<p style='color: orange;'>⚠️ Le dossier n'existe pas, création...</p>";
    if (mkdir($uploadDir, 0777, true)) {
        echo "<p style='color: green;'>✅ Dossier créé avec succès : <code>$uploadDir</code></p>";
    } else {
        echo "<p style='color: red;'>❌ Impossible de créer le dossier</p>";
        exit;
    }
} else {
    echo "<p style='color: green;'>✅ Le dossier existe : <code>$uploadDir</code></p>";
}

// Vérifier les permissions
$perms = substr(sprintf('%o', fileperms($uploadDir)), -4);
echo "<p><strong>Permissions :</strong> <code>$perms</code>";
if (is_writable($uploadDir)) {
    echo " <span style='color: green;'>✅ Écriture autorisée</span>";
} else {
    echo " <span style='color: red;'>❌ Pas d'écriture</span>";
}
echo "</p>";

// Lister les fichiers existants
$files = glob($uploadDir . '*');
echo "<p><strong>Fichiers existants :</strong> " . count($files) . "</p>";

if (count($files) > 0) {
    echo "<ul style='max-height: 200px; overflow-y: auto; border: 1px solid #ddd; padding: 10px;'>";
    foreach (array_slice($files, 0, 20) as $file) {
        $filename = basename($file);
        $size = filesize($file);
        $sizeKb = round($size / 1024, 2);
        echo "<li><code>$filename</code> - $sizeKb KB</li>";
    }
    if (count($files) > 20) {
        echo "<li><em>... et " . (count($files) - 20) . " autres fichiers</em></li>";
    }
    echo "</ul>";
}

// Vérifier l'endpoint API
echo "<h3>2. Test de l'endpoint API</h3>";

require_once __DIR__ . '/api/config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    echo "<p style='color: green;'>✅ Connexion à la base de données réussie</p>";
    
    // Vérifier la structure de la table contraventions
    echo "<h4>Structure de la table 'contraventions' :</h4>";
    $stmt = $db->query("DESCRIBE contraventions");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $hasPhotosColumn = false;
    echo "<table border='1' cellpadding='8' style='border-collapse: collapse;'>";
    echo "<tr style='background: #f0f0f0;'><th>Colonne</th><th>Type</th><th>Null</th><th>Default</th></tr>";
    foreach ($columns as $col) {
        if ($col['Field'] === 'photos') {
            $hasPhotosColumn = true;
            echo "<tr style='background: #e8f4e8;'>";
        } else {
            echo "<tr>";
        }
        echo "<td><strong>" . htmlspecialchars($col['Field']) . "</strong></td>";
        echo "<td>" . htmlspecialchars($col['Type']) . "</td>";
        echo "<td>" . htmlspecialchars($col['Null']) . "</td>";
        echo "<td>" . htmlspecialchars($col['Default'] ?? 'NULL') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    if ($hasPhotosColumn) {
        echo "<p style='color: green;'>✅ La colonne 'photos' existe</p>";
    } else {
        echo "<p style='color: red;'>❌ La colonne 'photos' n'existe pas !</p>";
        echo "<p><strong>Migration requise :</strong></p>";
        echo "<pre>ALTER TABLE contraventions ADD COLUMN photos TEXT NULL;</pre>";
    }
    
    // Afficher les dernières contraventions avec leurs photos
    echo "<h3>3. Dernières contraventions créées</h3>";
    $stmt = $db->query("SELECT id, type_dossier, photos, created_at FROM contraventions ORDER BY created_at DESC LIMIT 5");
    $recentCv = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($recentCv)) {
        echo "<p style='color: orange;'>Aucune contravention trouvée</p>";
    } else {
        echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr style='background: #f0f0f0;'><th>ID</th><th>Type</th><th>Photos</th><th>Créé le</th><th>Action</th></tr>";
        foreach ($recentCv as $cv) {
            $hasPhotos = !empty($cv['photos']);
            $bgColor = $hasPhotos ? '#e8f4e8' : '#fff3e0';
            
            echo "<tr style='background: $bgColor;'>";
            echo "<td><strong>" . $cv['id'] . "</strong></td>";
            echo "<td>" . htmlspecialchars($cv['type_dossier']) . "</td>";
            echo "<td>";
            if ($hasPhotos) {
                $photosCount = substr_count($cv['photos'], ',') + 1;
                echo "✅ $photosCount photo(s)<br>";
                echo "<code style='font-size: 10px;'>" . htmlspecialchars(substr($cv['photos'], 0, 50)) . "...</code>";
            } else {
                echo "❌ Aucune photo";
            }
            echo "</td>";
            echo "<td>" . $cv['created_at'] . "</td>";
            echo "<td>";
            echo "<a href='contravention_display.php?id=" . $cv['id'] . "' target='_blank'>Voir display</a> | ";
            echo "<a href='debug_contravention.php?id=" . $cv['id'] . "' target='_blank'>Debug</a>";
            echo "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
    // Instructions pour tester
    echo "<h3>4. Instructions de test</h3>";
    echo "<div style='background: #e8f4fd; padding: 15px; border-radius: 6px;'>";
    echo "<p><strong>Pour tester l'upload depuis Flutter :</strong></p>";
    echo "<ol>";
    echo "<li>Ouvrez l'application Flutter</li>";
    echo "<li>Créez une nouvelle contravention (particulier, entreprise ou véhicule)</li>";
    echo "<li>Ajoutez au moins une photo</li>";
    echo "<li>Cochez ou non 'Amende payée'</li>";
    echo "<li>Soumettez le formulaire</li>";
    echo "<li>Revenez sur cette page et actualisez</li>";
    echo "<li>Vérifiez que la nouvelle contravention apparaît avec des photos</li>";
    echo "</ol>";
    echo "</div>";
    
    echo "<h3>5. Logs du serveur</h3>";
    echo "<p>Pour voir les logs en temps réel, exécutez dans le terminal :</p>";
    echo "<pre style='background: #f5f5f5; padding: 10px;'>tail -f /var/log/php_errors.log</pre>";
    echo "<p>Ou consultez les logs Apache/Nginx selon votre configuration.</p>";
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Erreur : " . htmlspecialchars($e->getMessage()) . "</p>";
}
?>
