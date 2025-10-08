<?php
// Script pour vérifier la corruption des PDF
echo "=== Vérification des PDF corrompus ===\n\n";

$uploadDir = __DIR__ . '/api/uploads/contraventions/';

if (!is_dir($uploadDir)) {
    echo "❌ Dossier uploads n'existe pas: $uploadDir\n";
    exit(1);
}

$files = glob($uploadDir . '*.pdf');

if (empty($files)) {
    echo "ℹ️ Aucun fichier PDF trouvé dans $uploadDir\n";
} else {
    echo "📁 Dossier: $uploadDir\n";
    echo "📄 Fichiers PDF trouvés: " . count($files) . "\n\n";
    
    foreach ($files as $file) {
        $filename = basename($file);
        $size = filesize($file);
        
        echo "📄 Fichier: $filename\n";
        echo "📊 Taille: $size bytes\n";
        
        // Lire les premiers bytes pour vérifier le format
        $handle = fopen($file, 'rb');
        $header = fread($handle, 8);
        fclose($handle);
        
        echo "🔍 En-tête: " . bin2hex($header) . "\n";
        echo "📝 En-tête ASCII: " . $header . "\n";
        
        // Vérifier si c'est un vrai PDF
        if (strpos($header, '%PDF') === 0) {
            echo "✅ Format PDF valide\n";
        } else {
            echo "❌ Format PDF invalide (probablement du texte brut)\n";
            
            // Afficher le contenu si c'est du texte
            $content = file_get_contents($file);
            if (mb_check_encoding($content, 'UTF-8')) {
                echo "📝 Contenu (texte):\n";
                echo "---\n";
                echo substr($content, 0, 200) . (strlen($content) > 200 ? '...' : '') . "\n";
                echo "---\n";
            }
        }
        
        echo "\n";
    }
}

echo "=== Diagnostic ===\n";
echo "🔍 Problème identifié: Les 'PDF' sont en fait des fichiers texte\n";
echo "💡 Solution: Utiliser une vraie librairie PDF (TCPDF, DomPDF, etc.)\n";
echo "🛠️ Action requise: Remplacer createSimplePdf() par une vraie génération PDF\n";

echo "\n=== Test de génération PDF avec TCPDF ===\n";

// Vérifier si TCPDF est disponible
if (class_exists('TCPDF')) {
    echo "✅ TCPDF est disponible\n";
} else {
    echo "❌ TCPDF n'est pas installé\n";
    echo "📦 Installation requise: composer require tecnickcom/tcpdf\n";
}

// Vérifier si DomPDF est disponible
if (class_exists('Dompdf\\Dompdf')) {
    echo "✅ DomPDF est disponible\n";
} else {
    echo "❌ DomPDF n'est pas installé\n";
    echo "📦 Installation requise: composer require dompdf/dompdf\n";
}

echo "\n=== Recommandations ===\n";
echo "1. 🔧 Installer une librairie PDF (TCPDF ou DomPDF)\n";
echo "2. 🔄 Remplacer la méthode createSimplePdf()\n";
echo "3. 🧹 Supprimer les anciens fichiers corrompus\n";
echo "4. 🧪 Tester la génération avec de vrais PDF\n";

?>
