<?php
/**
 * Vérification des horaires de connexion pour l'utilisateur boom
 */

require_once __DIR__ . '/controllers/AuthController.php';

echo "=== VÉRIFICATION DES HORAIRES DE CONNEXION ===\n\n";

// Informations sur le jour actuel
$now = new DateTime('now');
$currentDay = (int)$now->format('N'); // 1-7 (1=lundi)
$currentTime = $now->format('H:i');
$dayNames = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

echo "Date et heure actuelles: " . $now->format('Y-m-d H:i:s') . "\n";
echo "Jour de la semaine: {$dayNames[$currentDay]} (numéro $currentDay)\n";
echo "Heure actuelle: $currentTime\n\n";

// Récupérer les horaires de l'utilisateur boom
try {
    $database = new Database();
    $db = $database->getConnection();
    
    $query = "SELECT login_schedule FROM users WHERE matricule = 'boom'";
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    if ($stmt->rowCount() > 0) {
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        $scheduleJson = $user['login_schedule'];
        
        echo "Horaires configurés pour 'boom':\n";
        echo $scheduleJson . "\n\n";
        
        $schedule = json_decode($scheduleJson, true);
        
        if ($schedule) {
            echo "=== ANALYSE DES HORAIRES ===\n";
            foreach ($dayNames as $num => $name) {
                if ($num == 0) continue;
                
                $daySchedule = $schedule[$name] ?? null;
                if ($daySchedule) {
                    $enabled = $daySchedule['enabled'] ?? false;
                    $start = $daySchedule['start'] ?? 'N/A';
                    $end = $daySchedule['end'] ?? 'N/A';
                    
                    $status = $enabled ? "✅ AUTORISÉ" : "❌ INTERDIT";
                    $current = ($num == $currentDay) ? " <- AUJOURD'HUI" : "";
                    
                    echo "$name: $status ($start - $end)$current\n";
                }
            }
            
            // Vérifier si la connexion est autorisée aujourd'hui
            $todayName = $dayNames[$currentDay];
            $todaySchedule = $schedule[$todayName] ?? null;
            
            echo "\n=== DIAGNOSTIC ===\n";
            if ($todaySchedule && isset($todaySchedule['enabled'])) {
                if ($todaySchedule['enabled']) {
                    echo "✅ Connexion AUTORISÉE aujourd'hui ($todayName)\n";
                    echo "Horaires: {$todaySchedule['start']} - {$todaySchedule['end']}\n";
                    
                    // Vérifier l'heure
                    $start = $todaySchedule['start'];
                    $end = $todaySchedule['end'];
                    if ($currentTime >= $start && $currentTime <= $end) {
                        echo "✅ Heure actuelle ($currentTime) dans la plage autorisée\n";
                    } else {
                        echo "❌ Heure actuelle ($currentTime) HORS de la plage autorisée ($start - $end)\n";
                    }
                } else {
                    echo "❌ Connexion INTERDITE aujourd'hui ($todayName)\n";
                    echo "C'est probablement la cause du problème !\n";
                }
            } else {
                echo "⚠️  Horaires non définis pour aujourd'hui\n";
            }
        }
    }
    
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
}

echo "\n=== SOLUTION ===\n";
echo "Si la connexion est interdite aujourd'hui, vous pouvez :\n";
echo "1. Modifier les horaires de l'utilisateur 'boom'\n";
echo "2. Changer son rôle en 'superadmin' (non soumis aux horaires)\n";
echo "3. Attendre le weekend (samedi/dimanche)\n";
?>
