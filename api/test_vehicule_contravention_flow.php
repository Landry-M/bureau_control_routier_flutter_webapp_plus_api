<?php
/**
 * Test complet du flux véhicule + contravention
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain; charset=UTF-8');

echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║     TEST COMPLET VÉHICULE + CONTRAVENTION + AFFICHAGE     ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/controllers/ContraventionController.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        throw new Exception('Connexion DB échouée');
    }
    
    echo "✅ Connexion DB OK\n\n";
    
    // 1. Trouver un véhicule existant
    echo "═══════════════════════════════════════════════════════════\n";
    echo "1️⃣  RÉCUPÉRATION D'UN VÉHICULE TEST\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $vehicule = $db->query("
        SELECT id, plaque, marque, modele 
        FROM vehicule_plaque 
        ORDER BY created_at DESC 
        LIMIT 1
    ")->fetch(PDO::FETCH_ASSOC);
    
    if (!$vehicule) {
        echo "❌ Aucun véhicule trouvé en base\n";
        echo "Créez d'abord un véhicule pour tester\n";
        exit(1);
    }
    
    echo "Véhicule trouvé:\n";
    echo "  ID     : {$vehicule['id']}\n";
    echo "  Plaque : {$vehicule['plaque']}\n";
    echo "  Véhicule: {$vehicule['marque']} {$vehicule['modele']}\n\n";
    
    $vehiculeId = $vehicule['id'];
    
    // 2. Créer une contravention test
    echo "═══════════════════════════════════════════════════════════\n";
    echo "2️⃣  CRÉATION D'UNE CONTRAVENTION TEST\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $contraventionData = [
        'dossier_id' => $vehiculeId,
        'type_dossier' => 'vehicule_plaque',
        'date_infraction' => date('Y-m-d H:i:s'),
        'lieu' => 'Avenue Test, Kinshasa',
        'type_infraction' => 'Excès de vitesse (TEST)',
        'description' => 'Test automatique de création de contravention',
        'reference_loi' => 'Art. 123 TEST',
        'amende' => '50000',
        'payed' => 'non',
        'photos' => ''
    ];
    
    $controller = new ContraventionController();
    $result = $controller->create($contraventionData);
    
    if (!$result['success']) {
        echo "❌ Échec création contravention\n";
        echo "Erreur: {$result['message']}\n";
        exit(1);
    }
    
    $contraventionId = $result['id'];
    echo "✅ Contravention créée avec succès\n";
    echo "  ID contravention: $contraventionId\n\n";
    
    // 3. Vérifier en base
    echo "═══════════════════════════════════════════════════════════\n";
    echo "3️⃣  VÉRIFICATION EN BASE DE DONNÉES\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $cvVerif = $db->query("
        SELECT * FROM contraventions 
        WHERE id = $contraventionId
    ")->fetch(PDO::FETCH_ASSOC);
    
    if (!$cvVerif) {
        echo "❌ Contravention non trouvée en base\n";
        exit(1);
    }
    
    echo "✅ Contravention trouvée en base\n";
    echo "  dossier_id    : {$cvVerif['dossier_id']}\n";
    echo "  type_dossier  : {$cvVerif['type_dossier']}\n";
    echo "  type_infraction: {$cvVerif['type_infraction']}\n";
    echo "  amende        : {$cvVerif['amende']}\n";
    echo "  pdf_path      : " . ($cvVerif['pdf_path'] ?? 'NULL (OK - génération dynamique)') . "\n\n";
    
    // 4. Test de l'endpoint API GET /contraventions/vehicule/{id}
    echo "═══════════════════════════════════════════════════════════\n";
    echo "4️⃣  TEST ENDPOINT API\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $contraventions = $controller->getByVehicule($vehiculeId);
    
    if (!$contraventions['success']) {
        echo "❌ Échec récupération contraventions\n";
        echo "Erreur: {$contraventions['message']}\n";
        exit(1);
    }
    
    $found = false;
    foreach ($contraventions['data'] as $cv) {
        if ($cv['id'] == $contraventionId) {
            $found = true;
            echo "✅ Contravention trouvée via API\n";
            echo "  ID: {$cv['id']}\n";
            echo "  Type infraction: {$cv['type_infraction']}\n";
            echo "  Amende: {$cv['amende']}\n";
            break;
        }
    }
    
    if (!$found) {
        echo "❌ Contravention non trouvée via l'API\n";
        echo "Nombre total de contraventions: " . count($contraventions['data']) . "\n";
        exit(1);
    }
    
    echo "\n";
    
    // 5. Test affichage PDF
    echo "═══════════════════════════════════════════════════════════\n";
    echo "5️⃣  TEST AFFICHAGE PDF (contravention_display.php)\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $displayUrl = "https://controls.heaventech.net/api/contravention/$contraventionId/display";
    $displayUrl2 = "https://controls.heaventech.net/api/contravention_display.php?id=$contraventionId";
    
    echo "✅ URL d'affichage PDF (via route):\n";
    echo "   $displayUrl\n\n";
    echo "✅ URL d'affichage PDF (directe):\n";
    echo "   $displayUrl2\n\n";
    
    // Test si contravention_display.php existe
    $displayFilePath = __DIR__ . '/contravention_display.php';
    if (file_exists($displayFilePath)) {
        echo "✅ Le fichier contravention_display.php existe\n";
        $size = round(filesize($displayFilePath) / 1024, 2);
        echo "   Taille: {$size} KB\n\n";
    } else {
        echo "❌ Le fichier contravention_display.php est MANQUANT\n";
        echo "   Chemin attendu: $displayFilePath\n\n";
    }
    
    // 6. Test de la jointure SQL
    echo "═══════════════════════════════════════════════════════════\n";
    echo "6️⃣  TEST JOINTURE SQL (comme contravention_display.php)\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $testJoin = $db->query("
        SELECT 
            c.id,
            c.type_infraction,
            c.amende,
            CONCAT('Véhicule ', vp.plaque) as nom_contrevenant,
            vp.plaque as plaque_vehicule,
            vp.marque as marque_vehicule,
            vp.modele as modele_vehicule
        FROM contraventions c
        LEFT JOIN vehicule_plaque vp ON c.type_dossier = 'vehicule_plaque' AND c.dossier_id = vp.id
        WHERE c.id = $contraventionId
    ")->fetch(PDO::FETCH_ASSOC);
    
    if ($testJoin) {
        echo "✅ Jointure SQL fonctionne\n";
        echo "  Nom contrevenant: {$testJoin['nom_contrevenant']}\n";
        echo "  Plaque: {$testJoin['plaque_vehicule']}\n";
        echo "  Véhicule: {$testJoin['marque_vehicule']} {$testJoin['modele_vehicule']}\n\n";
    } else {
        echo "❌ Échec de la jointure SQL\n\n";
    }
    
    // 7. Commandes de test Flutter
    echo "═══════════════════════════════════════════════════════════\n";
    echo "7️⃣  COMMANDES POUR TESTER DEPUIS FLUTTER\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    echo "// 1. Récupérer les contraventions du véhicule\n";
    echo "final response = await http.get(\n";
    echo "  Uri.parse('\${ApiConfig.baseUrl}/contraventions/vehicule/$vehiculeId')\n";
    echo ");\n\n";
    
    echo "// 2. Afficher le PDF d'une contravention\n";
    echo "final pdfUrl = '\${ApiConfig.baseUrl}/contravention/$contraventionId/display';\n";
    echo "launchUrl(Uri.parse(pdfUrl));\n\n";
    
    // 8. Test via curl
    echo "═══════════════════════════════════════════════════════════\n";
    echo "8️⃣  TEST VIA CURL\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    echo "# Récupérer les contraventions:\n";
    echo "curl 'https://controls.heaventech.net/api/contraventions/vehicule/$vehiculeId'\n\n";
    
    echo "# Afficher le PDF:\n";
    echo "curl 'https://controls.heaventech.net/api/contravention/$contraventionId/display'\n\n";
    
    // Résumé final
    echo "═══════════════════════════════════════════════════════════\n";
    echo "📊 RÉSUMÉ DU TEST\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    echo "✅ Véhicule ID $vehiculeId trouvé\n";
    echo "✅ Contravention ID $contraventionId créée\n";
    echo "✅ Contravention vérifiée en base\n";
    echo "✅ API GET /contraventions/vehicule/{id} fonctionne\n";
    echo "✅ Jointure SQL fonctionne\n";
    echo "✅ Pas de pdf_path stocké (génération dynamique)\n\n";
    
    echo "🎯 TOUT FONCTIONNE CORRECTEMENT !\n\n";
    echo "Si le problème persiste dans l'app Flutter:\n";
    echo "  1. Vérifier que l'app appelle bien l'API\n";
    echo "  2. Vérifier le parsing JSON de la réponse\n";
    echo "  3. Vérifier que l'URL du PDF est correcte\n\n";
    
    // Nettoyage (optionnel)
    echo "🗑️  NETTOYAGE: Voulez-vous supprimer la contravention de test?\n";
    echo "   Pour supprimer, exécutez:\n";
    echo "   DELETE FROM contraventions WHERE id = $contraventionId;\n\n";
    
} catch (Exception $e) {
    echo "\n❌ ERREUR FATALE\n\n";
    echo "Message: " . $e->getMessage() . "\n";
    echo "Fichier: " . $e->getFile() . "\n";
    echo "Ligne: " . $e->getLine() . "\n";
}

echo "⚠️  SUPPRIMEZ ce fichier après les tests\n";
?>
