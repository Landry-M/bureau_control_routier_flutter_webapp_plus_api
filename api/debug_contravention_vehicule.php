<?php
/**
 * Script de debug pour les contraventions de véhicules
 */

require_once __DIR__ . '/config/database.php';

header('Content-Type: text/html; charset=utf-8');

try {
    $database = new Database();
    $pdo = $database->getConnection();
    
    if (!$pdo) {
        die('Erreur de connexion à la base de données');
    }
    
    echo "<h1>Debug Contraventions Véhicules</h1>";
    
    // Récupérer les 5 dernières contraventions de type vehicule_plaque
    $stmt = $pdo->prepare("
        SELECT 
            c.id,
            c.type_dossier,
            c.dossier_id,
            c.type_infraction,
            c.lieu,
            c.date_infraction,
            vp.id as vehicule_id,
            vp.plaque,
            vp.marque,
            vp.modele,
            vp.couleur
        FROM contraventions c
        LEFT JOIN vehicule_plaque vp ON (c.type_dossier = 'vehicule_plaque' AND c.dossier_id = vp.id)
        WHERE c.type_dossier = 'vehicule_plaque'
        ORDER BY c.id DESC
        LIMIT 5
    ");
    
    $stmt->execute();
    $contraventions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<h2>Contraventions de véhicules (5 dernières)</h2>";
    echo "<p>Nombre trouvé: " . count($contraventions) . "</p>";
    
    if (empty($contraventions)) {
        echo "<p style='color: orange;'>Aucune contravention de véhicule trouvée.</p>";
    } else {
        echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
        echo "<tr>
                <th>ID Contrav.</th>
                <th>Type Dossier</th>
                <th>Dossier ID</th>
                <th>Véhicule ID (JOIN)</th>
                <th>Plaque</th>
                <th>Marque</th>
                <th>Modèle</th>
                <th>Couleur</th>
                <th>Type Infraction</th>
                <th>Lieu</th>
              </tr>";
        
        foreach ($contraventions as $c) {
            $plaqueStyle = empty($c['plaque']) ? 'background-color: #ffcccc;' : 'background-color: #ccffcc;';
            $vehiculeIdStyle = ($c['dossier_id'] == $c['vehicule_id']) ? 'background-color: #ccffcc;' : 'background-color: #ffcccc;';
            
            echo "<tr>";
            echo "<td>" . htmlspecialchars($c['id']) . "</td>";
            echo "<td>" . htmlspecialchars($c['type_dossier']) . "</td>";
            echo "<td>" . htmlspecialchars($c['dossier_id']) . "</td>";
            echo "<td style='$vehiculeIdStyle'>" . htmlspecialchars($c['vehicule_id'] ?? 'NULL') . "</td>";
            echo "<td style='$plaqueStyle'>" . htmlspecialchars($c['plaque'] ?? 'NULL') . "</td>";
            echo "<td>" . htmlspecialchars($c['marque'] ?? 'NULL') . "</td>";
            echo "<td>" . htmlspecialchars($c['modele'] ?? 'NULL') . "</td>";
            echo "<td>" . htmlspecialchars($c['couleur'] ?? 'NULL') . "</td>";
            echo "<td>" . htmlspecialchars($c['type_infraction']) . "</td>";
            echo "<td>" . htmlspecialchars($c['lieu']) . "</td>";
            echo "</tr>";
        }
        
        echo "</table>";
        
        echo "<h3>Légende :</h3>";
        echo "<ul>";
        echo "<li><span style='background-color: #ccffcc; padding: 2px 5px;'>Vert</span> = Données OK</li>";
        echo "<li><span style='background-color: #ffcccc; padding: 2px 5px;'>Rouge</span> = Problème détecté</li>";
        echo "</ul>";
    }
    
    // Vérifier s'il y a des contraventions avec dossier_id ne correspondant à aucun véhicule
    echo "<h2>Vérification des IDs</h2>";
    
    $stmtCheck = $pdo->prepare("
        SELECT 
            c.id,
            c.dossier_id,
            CASE 
                WHEN vp.id IS NULL THEN 'VÉHICULE NON TROUVÉ'
                ELSE 'OK'
            END as status,
            vp.plaque
        FROM contraventions c
        LEFT JOIN vehicule_plaque vp ON c.dossier_id = vp.id
        WHERE c.type_dossier = 'vehicule_plaque'
        ORDER BY c.id DESC
        LIMIT 10
    ");
    
    $stmtCheck->execute();
    $checkResults = $stmtCheck->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr><th>ID Contravention</th><th>Dossier ID</th><th>Status</th><th>Plaque</th></tr>";
    
    foreach ($checkResults as $r) {
        $style = ($r['status'] === 'OK') ? 'background-color: #ccffcc;' : 'background-color: #ffcccc;';
        echo "<tr style='$style'>";
        echo "<td>" . htmlspecialchars($r['id']) . "</td>";
        echo "<td>" . htmlspecialchars($r['dossier_id']) . "</td>";
        echo "<td><strong>" . htmlspecialchars($r['status']) . "</strong></td>";
        echo "<td>" . htmlspecialchars($r['plaque'] ?? 'NULL') . "</td>";
        echo "</tr>";
    }
    
    echo "</table>";
    
} catch (Exception $e) {
    echo "<p style='color: red;'>Erreur: " . htmlspecialchars($e->getMessage()) . "</p>";
}
?>
