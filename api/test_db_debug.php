<?php
/**
 * Test avec DatabaseDebug pour voir l'erreur RÉELLE
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain; charset=UTF-8');

echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║     TEST DE CONNEXION AVEC AFFICHAGE ERREURS RÉELLES      ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n";

try {
    require_once __DIR__ . '/config/database_debug.php';
    
    echo "\n📡 Tentative de connexion...\n\n";
    
    $db = new DatabaseDebug();
    $conn = $db->getConnection();
    
    if ($conn) {
        echo "\n";
        echo "╔════════════════════════════════════════════════════════════╗\n";
        echo "║                ✅ CONNEXION RÉUSSIE !                     ║\n";
        echo "╚════════════════════════════════════════════════════════════╝\n\n";
        
        echo "Test de requête...\n";
        $version = $conn->query("SELECT VERSION()")->fetchColumn();
        echo "MySQL Version : $version\n\n";
        
        echo "Le problème n'est PAS la connexion MySQL.\n";
        echo "Vérifiez plutôt :\n";
        echo "  • Les permissions des fichiers\n";
        echo "  • Le cache PHP (opcache)\n";
        echo "  • Les logs PHP\n";
    }
    
} catch (Exception $e) {
    echo "\n";
    echo "╔════════════════════════════════════════════════════════════╗\n";
    echo "║              ❌ ERREUR DE CONNEXION                        ║\n";
    echo "╚════════════════════════════════════════════════════════════╝\n\n";
    
    echo "Type d'erreur : " . get_class($e) . "\n";
    echo "Message       : " . $e->getMessage() . "\n";
    echo "Code          : " . $e->getCode() . "\n";
    echo "Fichier       : " . $e->getFile() . "\n";
    echo "Ligne         : " . $e->getLine() . "\n\n";
    
    echo "Trace complète :\n";
    echo $e->getTraceAsString() . "\n";
}

echo "\n⚠️  SUPPRIMEZ ces fichiers après diagnostic :\n";
echo "   • /api/config/database_debug.php\n";
echo "   • /api/test_db_debug.php\n";
echo "   • /api/debug_connection.php\n";
?>
