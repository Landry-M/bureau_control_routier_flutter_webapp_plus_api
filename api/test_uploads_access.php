<?php
/**
 * Script de test pour vérifier l'accès au dossier uploads
 * Usage: Accéder à ce fichier via le navigateur
 */

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test d'accès au dossier uploads</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 900px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 10px;
        }
        .test-item {
            margin: 15px 0;
            padding: 15px;
            border-left: 4px solid #ddd;
            background: #f9f9f9;
        }
        .success {
            border-left-color: #4CAF50;
            background: #e8f5e9;
        }
        .error {
            border-left-color: #f44336;
            background: #ffebee;
        }
        .warning {
            border-left-color: #ff9800;
            background: #fff3e0;
        }
        .label {
            font-weight: bold;
            color: #555;
        }
        .value {
            margin-top: 5px;
            font-family: monospace;
            background: white;
            padding: 5px;
            border-radius: 3px;
        }
        ul {
            margin: 10px 0;
            padding-left: 20px;
        }
        .status {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: bold;
        }
        .status.ok {
            background: #4CAF50;
            color: white;
        }
        .status.fail {
            background: #f44336;
            color: white;
        }
        .status.warn {
            background: #ff9800;
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Test d'accès au dossier uploads</h1>
        
        <?php
        $uploadsDir = __DIR__ . '/uploads';
        $tests = [];
        
        // Test 1: Dossier uploads existe
        $tests[] = [
            'name' => 'Dossier uploads existe',
            'status' => is_dir($uploadsDir),
            'message' => is_dir($uploadsDir) 
                ? "Le dossier uploads existe : $uploadsDir" 
                : "❌ Le dossier uploads n'existe pas"
        ];
        
        // Test 2: Permissions du dossier
        $perms = is_dir($uploadsDir) ? substr(sprintf('%o', fileperms($uploadsDir)), -4) : 'N/A';
        $tests[] = [
            'name' => 'Permissions du dossier uploads',
            'status' => $perms >= '0755',
            'message' => "Permissions actuelles : $perms " . ($perms >= '0755' ? '✅' : '⚠️ Recommandé: 0755')
        ];
        
        // Test 3: Fichier .htaccess dans uploads
        $htaccessPath = $uploadsDir . '/.htaccess';
        $tests[] = [
            'name' => 'Fichier .htaccess dans uploads',
            'status' => file_exists($htaccessPath),
            'message' => file_exists($htaccessPath)
                ? "✅ Fichier .htaccess présent"
                : "❌ Fichier .htaccess manquant"
        ];
        
        // Test 4: Sous-dossiers uploads
        $subfolders = ['contraventions', 'permis_temporaire', 'particuliers', 'vehicules', 'entreprises'];
        $missingFolders = [];
        foreach ($subfolders as $folder) {
            if (!is_dir($uploadsDir . '/' . $folder)) {
                $missingFolders[] = $folder;
            }
        }
        $tests[] = [
            'name' => 'Sous-dossiers uploads',
            'status' => empty($missingFolders),
            'message' => empty($missingFolders)
                ? "✅ Tous les sous-dossiers requis existent"
                : "⚠️ Dossiers manquants : " . implode(', ', $missingFolders)
        ];
        
        // Test 5: Fichiers dans contraventions
        $contraventionsDir = $uploadsDir . '/contraventions';
        $files = is_dir($contraventionsDir) ? array_diff(scandir($contraventionsDir), ['.', '..', '.DS_Store']) : [];
        $tests[] = [
            'name' => 'Fichiers dans contraventions',
            'status' => count($files) > 0,
            'message' => count($files) > 0
                ? "✅ " . count($files) . " fichier(s) trouvé(s)"
                : "ℹ️ Aucun fichier (normal si nouveau déploiement)"
        ];
        
        // Test 6: Module Apache mod_rewrite
        $modRewrite = in_array('mod_rewrite', apache_get_modules());
        $tests[] = [
            'name' => 'Module Apache mod_rewrite',
            'status' => $modRewrite,
            'message' => $modRewrite
                ? "✅ mod_rewrite est activé"
                : "❌ mod_rewrite n'est pas activé (requis pour .htaccess)"
        ];
        
        // Test 7: Configuration PHP upload
        $uploadMaxFilesize = ini_get('upload_max_filesize');
        $postMaxSize = ini_get('post_max_size');
        $tests[] = [
            'name' => 'Configuration PHP upload',
            'status' => true,
            'message' => "upload_max_filesize: $uploadMaxFilesize | post_max_size: $postMaxSize"
        ];
        
        // Affichage des résultats
        $totalTests = count($tests);
        $passedTests = count(array_filter($tests, function($t) { return $t['status']; }));
        
        echo "<div class='test-item " . ($passedTests === $totalTests ? 'success' : 'warning') . "'>";
        echo "<strong>Résultat global : $passedTests/$totalTests tests réussis</strong>";
        echo "</div>";
        
        foreach ($tests as $test) {
            $class = $test['status'] ? 'success' : 'error';
            $statusLabel = $test['status'] ? 'ok' : 'fail';
            
            echo "<div class='test-item $class'>";
            echo "<div class='label'>{$test['name']} ";
            echo "<span class='status $statusLabel'>" . ($test['status'] ? 'OK' : 'FAIL') . "</span>";
            echo "</div>";
            echo "<div class='value'>{$test['message']}</div>";
            echo "</div>";
        }
        ?>
        
        <h2>📋 URLs de test</h2>
        <div class="test-item">
            <p><strong>Pour tester l'accès direct aux fichiers :</strong></p>
            <ul>
                <?php
                // Récupérer un fichier exemple s'il existe
                if (is_dir($contraventionsDir)) {
                    $files = array_diff(scandir($contraventionsDir), ['.', '..', '.DS_Store']);
                    if (count($files) > 0) {
                        $exampleFile = reset($files);
                        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
                        $host = $_SERVER['HTTP_HOST'];
                        $baseUrl = $protocol . '://' . $host . dirname($_SERVER['PHP_SELF']);
                        $testUrl = $baseUrl . '/uploads/contraventions/' . $exampleFile;
                        
                        echo "<li>URL de test : <a href='$testUrl' target='_blank'>$testUrl</a></li>";
                        echo "<li>Si le fichier s'ouvre ✅ = Accès uploads fonctionnel</li>";
                        echo "<li>Si erreur 403/404 ❌ = Vérifier la configuration</li>";
                    } else {
                        echo "<li>ℹ️ Aucun fichier dans contraventions pour tester</li>";
                        echo "<li>Uploadez un fichier puis rafraîchissez cette page</li>";
                    }
                }
                ?>
            </ul>
        </div>
        
        <h2>🔧 Recommandations</h2>
        <div class="test-item">
            <?php if ($passedTests === $totalTests): ?>
                <p style="color: #4CAF50; font-weight: bold;">✅ Configuration optimale ! Le dossier uploads devrait être accessible.</p>
            <?php else: ?>
                <p style="color: #ff9800; font-weight: bold;">⚠️ Certains tests ont échoué. Consultez les détails ci-dessus.</p>
                <p><strong>Actions recommandées :</strong></p>
                <ul>
                    <li>Vérifier que AllowOverride All est activé dans la config Apache</li>
                    <li>Vérifier les permissions : <code>chmod 755 uploads</code></li>
                    <li>Vérifier que mod_rewrite est activé</li>
                    <li>Consulter le fichier DEPLOIEMENT_UPLOADS.md pour plus de détails</li>
                </ul>
            <?php endif; ?>
        </div>
        
        <h2>📁 Structure du dossier uploads</h2>
        <div class="test-item">
            <div class="value">
                <?php
                function displayTree($dir, $prefix = '') {
                    if (!is_dir($dir)) return;
                    
                    $items = array_diff(scandir($dir), ['.', '..', '.DS_Store']);
                    foreach ($items as $item) {
                        $path = $dir . '/' . $item;
                        if (is_dir($path)) {
                            echo $prefix . "📁 $item/\n";
                            $files = array_diff(scandir($path), ['.', '..', '.DS_Store']);
                            echo $prefix . "   (" . count($files) . " fichier(s))\n";
                        }
                    }
                }
                
                echo "<pre>";
                echo "uploads/\n";
                displayTree($uploadsDir, '  ');
                echo "</pre>";
                ?>
            </div>
        </div>
    </div>
</body>
</html>
