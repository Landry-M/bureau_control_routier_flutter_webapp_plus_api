<?php
/**
 * Test de la logique de vérification des horaires
 */

require_once __DIR__ . '/controllers/AuthController.php';

echo "=== TEST DE LA LOGIQUE DES HORAIRES ===\n\n";

// Récupérer les horaires de l'utilisateur boom
try {
    $database = new Database();
    $db = $database->getConnection();
    
    $query = "SELECT login_schedule, role FROM users WHERE matricule = 'boom'";
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    if ($stmt->rowCount() > 0) {
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        $scheduleJson = $user['login_schedule'];
        $role = $user['role'];
        
        echo "Rôle de l'utilisateur: $role\n";
        echo "Horaires JSON: $scheduleJson\n\n";
        
        // Décoder les horaires
        $schedule = json_decode($scheduleJson, true);
        
        echo "=== ANALYSE DU FORMAT ===\n";
        echo "Format détecté: ";
        if (isset($schedule['1']) || isset($schedule['2'])) {
            echo "Numérique (1-7)\n";
        } elseif (isset($schedule['Lundi']) || isset($schedule['Mardi'])) {
            echo "Textuel (Lundi, Mardi, etc.)\n";
        } else {
            echo "Inconnu\n";
        }
        
        // Test de la fonction actuelle
        $authController = new AuthController();
        
        // Utiliser la réflexion pour accéder à la méthode privée
        $reflection = new ReflectionClass($authController);
        $method = $reflection->getMethod('isWithinLoginSchedule');
        $method->setAccessible(true);
        
        $result = $method->invoke($authController, $scheduleJson);
        
        echo "\n=== RÉSULTAT DE LA FONCTION ACTUELLE ===\n";
        echo "isWithinLoginSchedule() retourne: " . ($result ? "TRUE (autorisé)" : "FALSE (interdit)") . "\n";
        
        // Vérification manuelle
        $now = new DateTime('now');
        $currentDay = (int)$now->format('N'); // 1-7 (1=lundi)
        $dayNames = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
        $todayName = $dayNames[$currentDay];
        
        echo "\n=== VÉRIFICATION MANUELLE ===\n";
        echo "Aujourd'hui: $todayName (numéro $currentDay)\n";
        
        if (isset($schedule[$todayName])) {
            $todaySchedule = $schedule[$todayName];
            echo "Horaires pour aujourd'hui: " . json_encode($todaySchedule) . "\n";
            echo "Enabled: " . ($todaySchedule['enabled'] ? 'true' : 'false') . "\n";
            
            if (!$todaySchedule['enabled']) {
                echo "❌ PROBLÈME IDENTIFIÉ: Le samedi est désactivé mais la connexion est autorisée!\n";
                echo "La fonction ne gère pas correctement le format textuel des jours.\n";
            }
        }
        
        echo "\n=== SOLUTION NÉCESSAIRE ===\n";
        echo "La fonction isWithinLoginSchedule() doit être corrigée pour gérer\n";
        echo "les clés textuelles (Lundi, Mardi, etc.) en plus des clés numériques.\n";
    }
    
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
}
?>
