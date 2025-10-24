<?php
/**
 * Script de correction : Convertir les valeurs '0'/'1' de la colonne 'payed'
 * en 'non'/'oui' pour toutes les contraventions existantes
 */

require_once __DIR__ . '/api/config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    echo "<h2>🔧 Correction des valeurs 'payed' dans les contraventions</h2>";
    
    // Compter les contraventions avec '0' ou '1'
    $stmt = $db->query("SELECT COUNT(*) as total FROM contraventions WHERE payed IN ('0', '1')");
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    $totalToFix = $result['total'];
    
    echo "<p><strong>Contraventions à corriger :</strong> $totalToFix</p>";
    
    if ($totalToFix == 0) {
        echo "<p style='color: green;'>✅ Toutes les contraventions sont déjà au bon format !</p>";
        exit;
    }
    
    // Afficher les contraventions avant correction
    echo "<h3>Avant correction :</h3>";
    $stmt = $db->query("SELECT id, type_dossier, payed FROM contraventions WHERE payed IN ('0', '1') LIMIT 10");
    $before = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<table border='1' cellpadding='8' style='border-collapse: collapse;'>";
    echo "<tr style='background: #f0f0f0;'><th>ID</th><th>Type dossier</th><th>Payed (avant)</th></tr>";
    foreach ($before as $cv) {
        echo "<tr>";
        echo "<td>" . htmlspecialchars($cv['id']) . "</td>";
        echo "<td>" . htmlspecialchars($cv['type_dossier']) . "</td>";
        echo "<td><code>" . htmlspecialchars($cv['payed']) . "</code></td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Demander confirmation
    echo "<br><form method='post'>";
    echo "<p><strong>⚠️ Cette opération va modifier $totalToFix contravention(s).</strong></p>";
    echo "<ul>";
    echo "<li>'0' sera converti en 'non'</li>";
    echo "<li>'1' sera converti en 'oui'</li>";
    echo "</ul>";
    echo "<button type='submit' name='confirm' value='1' style='padding: 10px 20px; background: #00509e; color: white; border: none; border-radius: 4px; cursor: pointer;'>Confirmer la correction</button>";
    echo " ";
    echo "<button type='button' onclick='window.location.reload()' style='padding: 10px 20px; background: #999; color: white; border: none; border-radius: 4px; cursor: pointer;'>Annuler</button>";
    echo "</form>";
    
    // Si confirmation, effectuer la correction
    if (isset($_POST['confirm']) && $_POST['confirm'] == '1') {
        echo "<hr>";
        echo "<h3>Exécution de la correction...</h3>";
        
        $db->beginTransaction();
        
        try {
            // Convertir '1' en 'oui'
            $stmt1 = $db->prepare("UPDATE contraventions SET payed = 'oui' WHERE payed = '1'");
            $stmt1->execute();
            $count1 = $stmt1->rowCount();
            echo "<p>✅ <strong>$count1</strong> contravention(s) marquée(s) comme 'oui' (payées)</p>";
            
            // Convertir '0' en 'non'
            $stmt0 = $db->prepare("UPDATE contraventions SET payed = 'non' WHERE payed = '0'");
            $stmt0->execute();
            $count0 = $stmt0->rowCount();
            echo "<p>✅ <strong>$count0</strong> contravention(s) marquée(s) comme 'non' (non payées)</p>";
            
            $db->commit();
            
            echo "<h3 style='color: green;'>✅ Correction terminée avec succès !</h3>";
            
            // Afficher les résultats après correction
            echo "<h3>Après correction (échantillon) :</h3>";
            $stmt = $db->query("SELECT id, type_dossier, payed FROM contraventions ORDER BY id DESC LIMIT 10");
            $after = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo "<table border='1' cellpadding='8' style='border-collapse: collapse;'>";
            echo "<tr style='background: #e8f4e8;'><th>ID</th><th>Type dossier</th><th>Payed (après)</th></tr>";
            foreach ($after as $cv) {
                $bgColor = $cv['payed'] === 'oui' ? '#e8f4e8' : '#fff3e0';
                echo "<tr style='background: $bgColor;'>";
                echo "<td>" . htmlspecialchars($cv['id']) . "</td>";
                echo "<td>" . htmlspecialchars($cv['type_dossier']) . "</td>";
                echo "<td><strong>" . htmlspecialchars($cv['payed']) . "</strong></td>";
                echo "</tr>";
            }
            echo "</table>";
            
            echo "<br><p><a href='contravention_display.php?id=" . $after[0]['id'] . "' target='_blank'>Voir la dernière contravention sur le display →</a></p>";
            
        } catch (Exception $e) {
            $db->rollBack();
            echo "<p style='color: red;'>❌ <strong>Erreur :</strong> " . htmlspecialchars($e->getMessage()) . "</p>";
        }
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'><strong>Erreur :</strong> " . htmlspecialchars($e->getMessage()) . "</p>";
}
?>
