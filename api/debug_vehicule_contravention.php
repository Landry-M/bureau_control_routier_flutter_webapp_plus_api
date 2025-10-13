<?php
/**
 * Script de diagnostic pour vérifier la création et l'affichage
 * des contraventions liées aux véhicules
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain; charset=UTF-8');

echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║   DIAGNOSTIC VÉHICULE + CONTRAVENTION + PDF               ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

require_once __DIR__ . '/config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        throw new Exception('Connexion base de données échouée');
    }
    
    echo "✅ Connexion base de données OK\n\n";
    
    // 1. Lister les derniers véhicules créés
    echo "═══════════════════════════════════════════════════════════\n";
    echo "📋 DERNIERS VÉHICULES CRÉÉS (10 derniers)\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $vehicules = $db->query("
        SELECT id, plaque, marque, modele, created_at 
        FROM vehicule_plaque 
        ORDER BY created_at DESC 
        LIMIT 10
    ")->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($vehicules as $v) {
        echo "ID: {$v['id']} | Plaque: {$v['plaque']} | {$v['marque']} {$v['modele']} | Créé: {$v['created_at']}\n";
    }
    
    if (empty($vehicules)) {
        echo "⚠️  Aucun véhicule trouvé\n";
        exit(1);
    }
    
    echo "\n";
    
    // 2. Lister toutes les contraventions de type vehicule_plaque
    echo "═══════════════════════════════════════════════════════════\n";
    echo "📄 CONTRAVENTIONS TYPE vehicule_plaque (10 dernières)\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $contraventions = $db->query("
        SELECT id, dossier_id, type_dossier, type_infraction, pdf_path, created_at 
        FROM contraventions 
        WHERE type_dossier = 'vehicule_plaque'
        ORDER BY created_at DESC 
        LIMIT 10
    ")->fetchAll(PDO::FETCH_ASSOC);
    
    if (!empty($contraventions)) {
        foreach ($contraventions as $c) {
            $pdfStatus = !empty($c['pdf_path']) ? '✅ PDF' : '❌ Pas de PDF';
            echo "ID: {$c['id']} | Véhicule ID: {$c['dossier_id']} | {$c['type_infraction']} | $pdfStatus | {$c['created_at']}\n";
            if (!empty($c['pdf_path'])) {
                echo "   PDF: {$c['pdf_path']}\n";
            }
        }
    } else {
        echo "⚠️  Aucune contravention de type vehicule_plaque trouvée\n";
        echo "\n📝 Cela signifie que :\n";
        echo "   1. Aucun véhicule n'a été créé avec contravention\n";
        echo "   2. Ou la création de la contravention échoue silencieusement\n\n";
    }
    
    echo "\n";
    
    // 3. Vérifier les liens véhicule <-> contravention
    echo "═══════════════════════════════════════════════════════════\n";
    echo "🔗 VÉRIFICATION DES LIENS VÉHICULE ↔ CONTRAVENTION\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $liens = $db->query("
        SELECT 
            v.id as vehicule_id,
            v.plaque,
            v.created_at as vehicule_created,
            c.id as contravention_id,
            c.type_infraction,
            c.pdf_path,
            c.created_at as contravention_created
        FROM vehicule_plaque v
        LEFT JOIN contraventions c ON (c.dossier_id = v.id AND c.type_dossier = 'vehicule_plaque')
        ORDER BY v.created_at DESC
        LIMIT 10
    ")->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($liens as $l) {
        $contraventionInfo = $l['contravention_id'] 
            ? "✅ Contravention #{$l['contravention_id']} - {$l['type_infraction']}"
            : "❌ Aucune contravention";
        
        echo "Véhicule #{$l['vehicule_id']} ({$l['plaque']}):\n";
        echo "  → $contraventionInfo\n";
        
        if ($l['contravention_id']) {
            if (!empty($l['pdf_path'])) {
                // Vérifier si le PDF existe physiquement
                $fullPath = __DIR__ . '/../' . $l['pdf_path'];
                if (file_exists($fullPath)) {
                    $size = round(filesize($fullPath) / 1024, 2);
                    echo "  → PDF: ✅ Existe ({$size} KB)\n";
                } else {
                    echo "  → PDF: ❌ Fichier manquant: {$l['pdf_path']}\n";
                }
            } else {
                echo "  → PDF: ❌ Aucun chemin enregistré\n";
            }
        }
        echo "\n";
    }
    
    // 4. Vérifier contravention_display.php
    echo "═══════════════════════════════════════════════════════════\n";
    echo "📄 VÉRIFICATION DU FICHIER contravention_display.php\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    $displayFiles = [
        '/api/contravention_display.php',
        '/contravention_display.php'
    ];
    
    foreach ($displayFiles as $file) {
        $fullPath = __DIR__ . '/..' . $file;
        if (file_exists($fullPath)) {
            $size = round(filesize($fullPath) / 1024, 2);
            echo "✅ $file existe ({$size} KB)\n";
        } else {
            echo "❌ $file MANQUANT\n";
        }
    }
    
    echo "\n";
    
    // 5. Test d'une création complète
    echo "═══════════════════════════════════════════════════════════\n";
    echo "🧪 RECOMMANDATIONS SELON LE DIAGNOSTIC\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    if (empty($contraventions)) {
        echo "❌ PROBLÈME: Aucune contravention créée\n\n";
        echo "Causes possibles:\n";
        echo "  1. La transaction échoue silencieusement\n";
        echo "  2. ContraventionController->create() échoue\n";
        echo "  3. Les images de contravention bloquent la création\n\n";
        echo "Solutions:\n";
        echo "  1. Vérifier les logs PHP\n";
        echo "  2. Tester la création sans images\n";
        echo "  3. Vérifier que la table contraventions existe\n\n";
    } elseif (count(array_filter($contraventions, fn($c) => empty($c['pdf_path']))) > 0) {
        echo "⚠️  PROBLÈME: Contraventions créées mais PDF manquants\n\n";
        echo "Causes possibles:\n";
        echo "  1. wkhtmltopdf n'est pas installé sur le serveur\n";
        echo "  2. Permissions d'écriture manquantes dans /uploads/contraventions/\n";
        echo "  3. Erreur silencieuse lors de la génération du PDF\n\n";
        echo "Solutions:\n";
        echo "  1. Vérifier: which wkhtmltopdf\n";
        echo "  2. Vérifier permissions: chmod 755 uploads/contraventions\n";
        echo "  3. Activer error_log pour voir les erreurs\n\n";
    } elseif (count(array_filter($liens, function($l) {
        if (!$l['pdf_path']) return false;
        $fullPath = __DIR__ . '/../' . $l['pdf_path'];
        return !file_exists($fullPath);
    })) > 0) {
        echo "⚠️  PROBLÈME: PDF enregistrés en base mais fichiers manquants\n\n";
        echo "Causes possibles:\n";
        echo "  1. Chemin pdf_path incorrect dans la base\n";
        echo "  2. Fichiers supprimés manuellement\n";
        echo "  3. Problème de synchronisation\n\n";
        echo "Solutions:\n";
        echo "  1. Vérifier le chemin dans pdf_path (doit commencer par uploads/)\n";
        echo "  2. Régénérer les PDF manquants\n\n";
    } else {
        echo "✅ TOUT SEMBLE OK\n\n";
        echo "Les contraventions sont créées et les PDF existent.\n\n";
        echo "Si le problème persiste côté Flutter:\n";
        echo "  1. Vérifier l'appel API: GET /contraventions/vehicule/{id}\n";
        echo "  2. Vérifier le parsing de la réponse JSON\n";
        echo "  3. Vérifier l'URL du PDF dans la réponse\n";
        echo "  4. Tester l'URL du PDF directement dans un navigateur\n\n";
    }
    
    // 6. Commandes de test
    echo "═══════════════════════════════════════════════════════════\n";
    echo "🧪 COMMANDES DE TEST\n";
    echo "═══════════════════════════════════════════════════════════\n\n";
    
    if (!empty($vehicules)) {
        $testVehiculeId = $vehicules[0]['id'];
        echo "Test API pour le véhicule #{$testVehiculeId}:\n";
        echo "  curl 'https://controls.heaventech.net/api/contraventions/vehicule/$testVehiculeId'\n\n";
    }
    
    if (!empty($contraventions)) {
        $testContraventionId = $contraventions[0]['id'];
        echo "Test affichage PDF contravention #{$testContraventionId}:\n";
        echo "  https://controls.heaventech.net/api/contravention/{$testContraventionId}/display\n\n";
    }
    
} catch (Exception $e) {
    echo "\n❌ ERREUR FATALE\n\n";
    echo "Message: " . $e->getMessage() . "\n";
    echo "Fichier: " . $e->getFile() . "\n";
    echo "Ligne: " . $e->getLine() . "\n";
}

echo "\n⚠️  SUPPRIMEZ ce fichier après diagnostic\n";
?>
