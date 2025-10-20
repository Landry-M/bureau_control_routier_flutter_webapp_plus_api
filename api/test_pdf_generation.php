<?php
/**
 * Script de test pour la génération de PDF d'avis de recherche
 */

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/controllers/AvisRecherchePdfController.php';

echo "=== Test de génération de PDF d'avis de recherche ===\n\n";

try {
    $database = new Database();
    $db = $database->getConnection();
    
    // Récupérer un avis de recherche existant
    $query = "SELECT id FROM avis_recherche ORDER BY id DESC LIMIT 1";
    $stmt = $db->query($query);
    $avis = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$avis) {
        echo "❌ Aucun avis de recherche trouvé dans la base de données\n";
        echo "Veuillez d'abord créer un avis de recherche via l'application\n";
        exit(1);
    }
    
    $avisId = $avis['id'];
    echo "📋 Test avec l'avis de recherche ID: $avisId\n\n";
    
    // Tester la génération de PDF
    echo "🔄 Génération du PDF...\n";
    $pdfController = new AvisRecherchePdfController();
    $result = $pdfController->generatePdf($avisId);
    
    if ($result['success']) {
        echo "✅ PDF généré avec succès!\n\n";
        echo "📁 Chemin du PDF: " . $result['pdf_path'] . "\n";
        echo "🔗 URL du PDF: " . $result['pdf_url'] . "\n\n";
        
        // Vérifier que le fichier existe
        if (file_exists($result['pdf_path'])) {
            $fileSize = filesize($result['pdf_path']);
            echo "📊 Taille du fichier: " . number_format($fileSize / 1024, 2) . " KB\n";
        } else {
            echo "⚠️  Le fichier PDF n'existe pas sur le disque\n";
        }
    } else {
        echo "❌ Erreur lors de la génération du PDF:\n";
        echo $result['message'] . "\n";
    }
    
    // Vérifier wkhtmltopdf
    echo "\n--- Vérification de wkhtmltopdf ---\n";
    $wkhtmltopdf = shell_exec('which wkhtmltopdf 2>/dev/null');
    if (empty(trim($wkhtmltopdf))) {
        echo "⚠️  wkhtmltopdf n'est pas installé\n";
        echo "Pour installer:\n";
        echo "  - macOS: brew install wkhtmltopdf\n";
        echo "  - Ubuntu/Debian: sudo apt-get install wkhtmltopdf\n";
        echo "  - Windows: https://wkhtmltopdf.org/downloads.html\n";
    } else {
        echo "✅ wkhtmltopdf est installé: " . trim($wkhtmltopdf) . "\n";
        $version = shell_exec('wkhtmltopdf --version 2>/dev/null');
        echo "Version: " . trim($version) . "\n";
    }
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    exit(1);
}

echo "\n=== Test terminé ===\n";
?>
