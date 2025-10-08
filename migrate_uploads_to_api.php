<?php
// Script pour migrer les fichiers uploads vers api/uploads
echo "=== Migration des fichiers uploads vers api/uploads ===\n\n";

$sourceDir = __DIR__ . '/uploads';
$targetDir = __DIR__ . '/api/uploads';

function migrateDirectory($source, $target, $dirName) {
    echo "Migration de $dirName...\n";
    
    if (!is_dir($source)) {
        echo "❌ Dossier source n'existe pas: $source\n";
        return false;
    }
    
    if (!is_dir($target)) {
        mkdir($target, 0755, true);
        echo "📁 Dossier cible créé: $target\n";
    }
    
    $files = scandir($source);
    $movedCount = 0;
    
    foreach ($files as $file) {
        if ($file === '.' || $file === '..') continue;
        
        $sourcePath = $source . '/' . $file;
        $targetPath = $target . '/' . $file;
        
        if (is_file($sourcePath)) {
            if (!file_exists($targetPath)) {
                if (copy($sourcePath, $targetPath)) {
                    echo "✅ Copié: $file\n";
                    $movedCount++;
                } else {
                    echo "❌ Échec copie: $file\n";
                }
            } else {
                echo "⚠️ Fichier existe déjà: $file\n";
            }
        }
    }
    
    echo "📊 $movedCount fichiers copiés pour $dirName\n\n";
    return true;
}

// Migrer chaque sous-dossier
$subdirs = [
    'accidents',
    'contraventions', 
    'entreprises',
    'particuliers',
    'permis_temporaire',
    'vehicules',
    'conducteurs'
];

foreach ($subdirs as $subdir) {
    $sourceSubdir = $sourceDir . '/' . $subdir;
    $targetSubdir = $targetDir . '/' . $subdir;
    
    migrateDirectory($sourceSubdir, $targetSubdir, $subdir);
}

// Vérifier la structure finale
echo "=== Vérification de la structure finale ===\n";

function listDirectoryContents($dir, $name) {
    echo "\n📁 Contenu de $name:\n";
    if (is_dir($dir)) {
        $items = scandir($dir);
        $fileCount = 0;
        foreach ($items as $item) {
            if ($item === '.' || $item === '..') continue;
            if (is_dir($dir . '/' . $item)) {
                $subItems = scandir($dir . '/' . $item);
                $subFileCount = count($subItems) - 2; // Exclure . et ..
                echo "  📂 $item/ ($subFileCount fichiers)\n";
            } else {
                $fileCount++;
            }
        }
        if ($fileCount > 0) {
            echo "  📄 $fileCount fichiers à la racine\n";
        }
    } else {
        echo "  ❌ Dossier n'existe pas\n";
    }
}

listDirectoryContents($sourceDir, 'uploads (ancien)');
listDirectoryContents($targetDir, 'api/uploads (nouveau)');

echo "\n=== Recommandations ===\n";
echo "1. Vérifiez que tous les fichiers ont été copiés correctement\n";
echo "2. Testez l'application pour s'assurer que les images s'affichent\n";
echo "3. Une fois confirmé, vous pouvez supprimer l'ancien dossier uploads/\n";
echo "4. Mettez à jour votre serveur web pour servir les fichiers depuis api/uploads/\n";

echo "\n=== Migration terminée ===\n";
?>
