<?php
/**
 * Script de diagnostic pour la table contraventions
 * Accès: http://localhost:8000/api/diagnostic_contraventions.php
 */

require_once __DIR__ . '/config/database.php';

header('Content-Type: text/html; charset=utf-8');

try {
    $database = new Database();
    $pdo = $database->getConnection();
    
    if (!$pdo) {
        throw new Exception('Impossible de se connecter à la base de données');
    }
    
    echo "<!DOCTYPE html>
    <html lang='fr'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Diagnostic Contraventions</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
            .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
            h1 { color: #00509e; }
            h2 { color: #333; border-bottom: 2px solid #00509e; padding-bottom: 10px; margin-top: 30px; }
            table { width: 100%; border-collapse: collapse; margin: 15px 0; }
            th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
            th { background: #00509e; color: white; }
            tr:nth-child(even) { background: #f9f9f9; }
            .success { color: green; font-weight: bold; }
            .warning { color: orange; font-weight: bold; }
            .error { color: red; font-weight: bold; }
            .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
            .stat-card { background: #f0f7ff; padding: 15px; border-radius: 8px; border-left: 4px solid #00509e; }
            .stat-card h3 { margin: 0 0 10px 0; color: #00509e; font-size: 14px; }
            .stat-card .value { font-size: 32px; font-weight: bold; color: #333; }
            pre { background: #f5f5f5; padding: 15px; border-radius: 4px; overflow-x: auto; }
        </style>
    </head>
    <body>
        <div class='container'>
            <h1>🔍 Diagnostic de la table contraventions</h1>
            <p><em>Exécuté le " . date('d/m/Y H:i:s') . "</em></p>";
    
    // 1. Vérifier la structure de la table
    echo "<h2>1. Structure de la table contraventions</h2>";
    $columns = $pdo->query("DESCRIBE contraventions")->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<table>
            <tr><th>Champ</th><th>Type</th><th>NULL</th><th>Clé</th><th>Défaut</th><th>Extra</th></tr>";
    
    $hasLieu = false;
    $hasAmende = false;
    
    foreach ($columns as $col) {
        if ($col['Field'] === 'lieu') $hasLieu = true;
        if ($col['Field'] === 'amende') $hasAmende = true;
        
        echo "<tr>
                <td>{$col['Field']}</td>
                <td>{$col['Type']}</td>
                <td>{$col['Null']}</td>
                <td>{$col['Key']}</td>
                <td>{$col['Default']}</td>
                <td>{$col['Extra']}</td>
              </tr>";
    }
    echo "</table>";
    
    // 2. Vérifier la présence des colonnes critiques
    echo "<h2>2. Vérification des colonnes critiques</h2>";
    echo "<ul>";
    echo "<li>Colonne 'lieu': " . ($hasLieu ? "<span class='success'>✓ Existe</span>" : "<span class='error'>✗ Manquante</span>") . "</li>";
    echo "<li>Colonne 'amende': " . ($hasAmende ? "<span class='success'>✓ Existe</span>" : "<span class='error'>✗ Manquante</span>") . "</li>";
    echo "</ul>";
    
    // 3. Statistiques sur les données
    echo "<h2>3. Statistiques des contraventions</h2>";
    $stats = $pdo->query("
        SELECT 
            COUNT(*) as total_contraventions,
            SUM(CASE WHEN lieu IS NULL OR lieu = '' THEN 1 ELSE 0 END) as lieu_vide,
            SUM(CASE WHEN amende IS NULL OR amende = '' OR amende = '0' THEN 1 ELSE 0 END) as amende_vide,
            SUM(CASE WHEN (lieu IS NOT NULL AND lieu != '') AND (amende IS NOT NULL AND amende != '' AND amende != '0') THEN 1 ELSE 0 END) as donnees_completes
        FROM contraventions
    ")->fetch(PDO::FETCH_ASSOC);
    
    echo "<div class='stats'>
            <div class='stat-card'>
                <h3>Total contraventions</h3>
                <div class='value'>{$stats['total_contraventions']}</div>
            </div>
            <div class='stat-card'>
                <h3>Lieu vide</h3>
                <div class='value' style='color: " . ($stats['lieu_vide'] > 0 ? 'orange' : 'green') . ";'>{$stats['lieu_vide']}</div>
            </div>
            <div class='stat-card'>
                <h3>Amende vide</h3>
                <div class='value' style='color: " . ($stats['amende_vide'] > 0 ? 'orange' : 'green') . ";'>{$stats['amende_vide']}</div>
            </div>
            <div class='stat-card'>
                <h3>Données complètes</h3>
                <div class='value' style='color: green;'>{$stats['donnees_completes']}</div>
            </div>
          </div>";
    
    // 4. Afficher les dernières contraventions
    echo "<h2>4. Dernières contraventions (10 plus récentes)</h2>";
    $contraventions = $pdo->query("
        SELECT 
            id,
            type_dossier,
            DATE_FORMAT(date_infraction, '%d/%m/%Y %H:%i') as date_infraction,
            CASE 
                WHEN lieu IS NULL THEN '<span class=\"error\">NULL</span>'
                WHEN lieu = '' THEN '<span class=\"warning\">(vide)</span>'
                ELSE lieu
            END as lieu,
            type_infraction,
            CASE 
                WHEN amende IS NULL THEN '<span class=\"error\">NULL</span>'
                WHEN amende = '' OR amende = '0' THEN '<span class=\"warning\">(vide/0)</span>'
                ELSE CONCAT(FORMAT(amende, 0), ' FC')
            END as amende,
            payed,
            DATE_FORMAT(created_at, '%d/%m/%Y %H:%i') as created_at
        FROM contraventions
        ORDER BY created_at DESC
        LIMIT 10
    ")->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<table>
            <tr>
                <th>ID</th>
                <th>Type</th>
                <th>Date infraction</th>
                <th>Lieu</th>
                <th>Type infraction</th>
                <th>Amende</th>
                <th>Payée</th>
                <th>Créée le</th>
            </tr>";
    
    foreach ($contraventions as $cv) {
        echo "<tr>
                <td>{$cv['id']}</td>
                <td>{$cv['type_dossier']}</td>
                <td>{$cv['date_infraction']}</td>
                <td>{$cv['lieu']}</td>
                <td>{$cv['type_infraction']}</td>
                <td>{$cv['amende']}</td>
                <td>{$cv['payed']}</td>
                <td>{$cv['created_at']}</td>
              </tr>";
    }
    echo "</table>";
    
    // 5. Recommandations
    echo "<h2>5. Recommandations</h2>";
    echo "<ul>";
    
    if (!$hasLieu) {
        echo "<li class='error'>⚠️ La colonne 'lieu' n'existe pas. Créez-la avec:
              <pre>ALTER TABLE contraventions ADD COLUMN lieu VARCHAR(500) DEFAULT NULL;</pre>
              </li>";
    }
    
    if (!$hasAmende) {
        echo "<li class='error'>⚠️ La colonne 'amende' n'existe pas. Créez-la avec:
              <pre>ALTER TABLE contraventions ADD COLUMN amende DECIMAL(15,2) DEFAULT 0;</pre>
              </li>";
    }
    
    if ($stats['lieu_vide'] > 0) {
        echo "<li class='warning'>⚠️ {$stats['lieu_vide']} contravention(s) ont le champ 'lieu' vide. 
              Vous pouvez les modifier via la modal d'édition.</li>";
    }
    
    if ($stats['amende_vide'] > 0) {
        echo "<li class='warning'>⚠️ {$stats['amende_vide']} contravention(s) ont le champ 'amende' vide ou à 0. 
              Vous pouvez les modifier via la modal d'édition.</li>";
    }
    
    if ($stats['donnees_completes'] == $stats['total_contraventions'] && $hasLieu && $hasAmende) {
        echo "<li class='success'>✓ Toutes les contraventions ont des données complètes !</li>";
    }
    
    echo "</ul>";
    
    echo "</div></body></html>";
    
} catch (Exception $e) {
    echo "<div style='color:red; padding:20px; background:#fff; margin:20px;'>
            <h2>Erreur</h2>
            <p>{$e->getMessage()}</p>
          </div>";
}
