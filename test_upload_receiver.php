<?php
/**
 * Script de test pour voir exactement ce que PHP reçoit lors de l'upload
 * À utiliser temporairement pour le debug
 */

header('Content-Type: text/html; charset=utf-8');

echo "<h2>🔍 Réception des données d'upload</h2>";
echo "<p>Timestamp: " . date('Y-m-d H:i:s') . "</p>";

// 1. Afficher $_POST
echo "<h3>1. Données POST ($_POST)</h3>";
if (empty($_POST)) {
    echo "<p style='color: orange;'>Aucune donnée POST</p>";
} else {
    echo "<pre style='background: #f5f5f5; padding: 10px; overflow-x: auto;'>";
    print_r($_POST);
    echo "</pre>";
}

// 2. Afficher $_FILES
echo "<h3>2. Fichiers reçus ($_FILES)</h3>";
if (empty($_FILES)) {
    echo "<p style='color: red;'>❌ Aucun fichier reçu</p>";
} else {
    echo "<p style='color: green;'>✅ Fichiers détectés</p>";
    echo "<pre style='background: #f5f5f5; padding: 10px; overflow-x: auto;'>";
    print_r($_FILES);
    echo "</pre>";
    
    // Analyser chaque clé de $_FILES
    foreach ($_FILES as $key => $fileData) {
        echo "<h4>Clé: <code>$key</code></h4>";
        
        if (is_array($fileData['name'])) {
            // Multiple files
            $count = count($fileData['name']);
            echo "<p style='color: blue;'>📦 Format tableau - <strong>$count fichier(s)</strong></p>";
            
            echo "<table border='1' cellpadding='8' style='border-collapse: collapse;'>";
            echo "<tr style='background: #f0f0f0;'>";
            echo "<th>#</th><th>Nom</th><th>Type</th><th>Taille</th><th>Erreur</th><th>Tmp name</th>";
            echo "</tr>";
            
            for ($i = 0; $i < $count; $i++) {
                $error = $fileData['error'][$i];
                $rowColor = $error === UPLOAD_ERR_OK ? '#e8f4e8' : '#ffe8e8';
                
                echo "<tr style='background: $rowColor;'>";
                echo "<td><strong>$i</strong></td>";
                echo "<td>" . htmlspecialchars($fileData['name'][$i]) . "</td>";
                echo "<td>" . htmlspecialchars($fileData['type'][$i]) . "</td>";
                echo "<td>" . number_format($fileData['size'][$i]) . " bytes</td>";
                echo "<td>";
                
                switch ($error) {
                    case UPLOAD_ERR_OK:
                        echo "✅ OK";
                        break;
                    case UPLOAD_ERR_INI_SIZE:
                        echo "❌ Fichier trop grand (php.ini)";
                        break;
                    case UPLOAD_ERR_FORM_SIZE:
                        echo "❌ Fichier trop grand (form)";
                        break;
                    case UPLOAD_ERR_PARTIAL:
                        echo "❌ Upload partiel";
                        break;
                    case UPLOAD_ERR_NO_FILE:
                        echo "❌ Pas de fichier";
                        break;
                    default:
                        echo "❌ Erreur $error";
                }
                
                echo "</td>";
                echo "<td><code style='font-size: 10px;'>" . htmlspecialchars($fileData['tmp_name'][$i]) . "</code></td>";
                echo "</tr>";
            }
            echo "</table>";
            
        } else {
            // Single file
            echo "<p style='color: blue;'>📄 Format fichier unique</p>";
            
            echo "<table border='1' cellpadding='8' style='border-collapse: collapse;'>";
            echo "<tr style='background: #f0f0f0;'><th>Propriété</th><th>Valeur</th></tr>";
            echo "<tr><td>Nom</td><td>" . htmlspecialchars($fileData['name']) . "</td></tr>";
            echo "<tr><td>Type</td><td>" . htmlspecialchars($fileData['type']) . "</td></tr>";
            echo "<tr><td>Taille</td><td>" . number_format($fileData['size']) . " bytes</td></tr>";
            echo "<tr><td>Erreur</td><td>" . $fileData['error'] . "</td></tr>";
            echo "<tr><td>Tmp name</td><td><code>" . htmlspecialchars($fileData['tmp_name']) . "</code></td></tr>";
            echo "</table>";
        }
    }
}

// 3. Afficher les headers
echo "<h3>3. Headers HTTP reçus</h3>";
$headers = getallheaders();
echo "<table border='1' cellpadding='8' style='border-collapse: collapse;'>";
echo "<tr style='background: #f0f0f0;'><th>Header</th><th>Valeur</th></tr>";
foreach ($headers as $name => $value) {
    if (stripos($name, 'content') !== false || stripos($name, 'type') !== false) {
        echo "<tr style='background: #e8f4fd;'>";
    } else {
        echo "<tr>";
    }
    echo "<td><strong>" . htmlspecialchars($name) . "</strong></td>";
    echo "<td>" . htmlspecialchars($value) . "</td>";
    echo "</tr>";
}
echo "</table>";

// 4. Configuration PHP
echo "<h3>4. Configuration PHP Upload</h3>";
echo "<table border='1' cellpadding='8' style='border-collapse: collapse;'>";
echo "<tr style='background: #f0f0f0;'><th>Directive</th><th>Valeur</th></tr>";
echo "<tr><td>upload_max_filesize</td><td><strong>" . ini_get('upload_max_filesize') . "</strong></td></tr>";
echo "<tr><td>post_max_size</td><td><strong>" . ini_get('post_max_size') . "</strong></td></tr>";
echo "<tr><td>max_file_uploads</td><td><strong>" . ini_get('max_file_uploads') . "</strong></td></tr>";
echo "<tr><td>memory_limit</td><td><strong>" . ini_get('memory_limit') . "</strong></td></tr>";
echo "</table>";

// 5. Test d'upload
if (!empty($_FILES)) {
    echo "<h3>5. Simulation d'upload</h3>";
    
    $uploadDir = __DIR__ . '/api/uploads/test_upload/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }
    
    echo "<p>Dossier de destination : <code>$uploadDir</code></p>";
    
    $uploadedCount = 0;
    
    foreach ($_FILES as $key => $fileData) {
        if (is_array($fileData['name'])) {
            for ($i = 0; $i < count($fileData['name']); $i++) {
                if ($fileData['error'][$i] === UPLOAD_ERR_OK) {
                    $fileName = 'test_' . uniqid() . '_' . $i . '_' . basename($fileData['name'][$i]);
                    $destPath = $uploadDir . $fileName;
                    
                    if (move_uploaded_file($fileData['tmp_name'][$i], $destPath)) {
                        echo "<p style='color: green;'>✅ Uploadé : <code>$fileName</code> (" . filesize($destPath) . " bytes)</p>";
                        $uploadedCount++;
                    } else {
                        echo "<p style='color: red;'>❌ Échec : <code>" . $fileData['name'][$i] . "</code></p>";
                    }
                }
            }
        } else {
            if ($fileData['error'] === UPLOAD_ERR_OK) {
                $fileName = 'test_' . uniqid() . '_' . basename($fileData['name']);
                $destPath = $uploadDir . $fileName;
                
                if (move_uploaded_file($fileData['tmp_name'], $destPath)) {
                    echo "<p style='color: green;'>✅ Uploadé : <code>$fileName</code> (" . filesize($destPath) . " bytes)</p>";
                    $uploadedCount++;
                } else {
                    echo "<p style='color: red;'>❌ Échec : <code>" . $fileData['name'] . "</code></p>";
                }
            }
        }
    }
    
    echo "<p><strong>Total uploadé : $uploadedCount fichier(s)</strong></p>";
}

// Formulaire de test HTML
if (empty($_FILES)) {
    echo "<hr>";
    echo "<h3>📤 Formulaire de test</h3>";
    echo "<form method='post' enctype='multipart/form-data'>";
    echo "<p><label>Sélectionner plusieurs fichiers :</label><br>";
    echo "<input type='file' name='photos[]' multiple accept='image/*'></p>";
    echo "<p><button type='submit' style='padding: 10px 20px; background: #00509e; color: white; border: none; border-radius: 4px; cursor: pointer;'>Envoyer</button></p>";
    echo "</form>";
    
    echo "<p><em>Note : Ce formulaire envoie les fichiers avec le nom 'photos[]' comme Flutter.</em></p>";
}
?>
