<?php
/**
 * Script de test pour vérifier l'utilisateur "testes" et ses horaires
 */

require_once __DIR__ . '/config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();

    if (!$db) {
        throw new Exception('Impossible de se connecter à la base de données');
    }

    echo "=== VÉRIFICATION UTILISATEUR 'testes' ===\n\n";

    // Récupérer l'utilisateur
    $query = "SELECT * FROM users WHERE matricule = 'testes' OR username = 'testes' LIMIT 1";
    $stmt = $db->query($query);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo "❌ Utilisateur 'testes' non trouvé dans la base de données.\n";
        exit(1);
    }

    echo "✅ Utilisateur trouvé:\n";
    echo "  - ID: " . $user['id'] . "\n";
    echo "  - Matricule: " . $user['matricule'] . "\n";
    echo "  - Username: " . $user['username'] . "\n";
    echo "  - Rôle: " . $user['role'] . "\n";
    echo "  - Statut: " . $user['statut'] . "\n";
    echo "  - Login Schedule: " . ($user['login_schedule'] ?? 'NULL') . "\n\n";

    // Afficher l'heure actuelle
    $now = new DateTime('now');
    echo "🕐 Heure actuelle:\n";
    echo "  - Date/Heure: " . $now->format('Y-m-d H:i:s') . "\n";
    echo "  - Heure: " . $now->format('H:i') . "\n";
    echo "  - Jour: " . $now->format('N') . " (" . getDayName((int)$now->format('N')) . ")\n\n";

    // Analyser le login_schedule
    if (empty($user['login_schedule'])) {
        echo "⚠️  Pas d'horaire défini → Accès autorisé par défaut\n";
        exit(0);
    }

    $scheduleJson = $user['login_schedule'];
    echo "📋 Analyse du login_schedule:\n";
    
    $data = json_decode($scheduleJson, true);
    if (!$data) {
        echo "❌ JSON invalide\n";
        echo "Contenu: " . $scheduleJson . "\n";
        exit(1);
    }

    echo "  - Format JSON valide ✅\n";
    echo "  - Contenu décodé:\n";
    print_r($data);
    echo "\n";

    // Vérifier si l'utilisateur peut se connecter maintenant
    $currentDay = (int)$now->format('N');
    $currentTime = $now->format('H:i');

    echo "🔍 Vérification de l'accès:\n";
    echo "  - Jour actuel: $currentDay\n";
    echo "  - Heure actuelle: $currentTime\n\n";

    $isAuthorized = isWithinLoginSchedule($scheduleJson);

    if ($isAuthorized) {
        echo "✅ AUTORISÉ - L'utilisateur peut se connecter maintenant\n";
    } else {
        echo "❌ REFUSÉ - L'utilisateur NE PEUT PAS se connecter maintenant\n";
    }

    echo "\n=== TEST DE CONNEXION ===\n\n";

    // Tester la connexion avec le mot de passe
    $passwordToTest = 'testes';
    $passwordMd5 = md5($passwordToTest);
    $storedPassword = $user['password'];

    echo "Test du mot de passe:\n";
    echo "  - Mot de passe testé: '$passwordToTest'\n";
    echo "  - MD5 calculé: $passwordMd5\n";
    echo "  - MD5 stocké: $storedPassword\n";
    
    if ($passwordMd5 === $storedPassword) {
        echo "  - ✅ Mot de passe correct\n";
    } else {
        echo "  - ❌ Mot de passe incorrect\n";
    }

} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    exit(1);
}

function isWithinLoginSchedule($scheduleJson) {
    try {
        $data = is_array($scheduleJson) ? $scheduleJson : json_decode($scheduleJson, true);
        if (!$data) return true;

        $now = new DateTime('now');
        $currentDay = (int)$now->format('N');
        $currentTime = $now->format('H:i');

        echo "  → Format de schedule détecté: ";

        // Helper to test a single window
        $inWindow = function($start, $end) use ($currentTime) {
            if (!is_string($start) || !is_string($end)) return false;
            echo "\n    Comparaison: $currentTime >= $start && $currentTime <= $end\n";
            $result = $currentTime >= $start && $currentTime <= $end;
            echo "    Résultat: " . ($result ? "DANS la plage" : "HORS de la plage") . "\n";
            return $result;
        };

        // Case 1: associative by day keys (numeric format)
        if (isset($data['1']) || isset($data['2']) || isset($data['3'])) {
            echo "Format numérique (1, 2, 3...)\n";
            $windows = $data[(string)$currentDay] ?? [];
            echo "  → Plages horaires pour le jour $currentDay:\n";
            print_r($windows);
            
            if (!is_array($windows)) return true;
            foreach ($windows as $w) {
                if ($inWindow($w['start'] ?? null, $w['end'] ?? null)) return true;
            }
            return false;
        }

        // Case 1b: associative by day names (textual format)
        $dayNames = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
        if (isset($data['Lundi']) || isset($data['Mardi'])) {
            echo "Format textuel (Lundi, Mardi...)\n";
            $todayName = $dayNames[$currentDay];
            $todaySchedule = $data[$todayName] ?? null;
            
            echo "  → Jour: $todayName\n";
            echo "  → Horaires du jour:\n";
            print_r($todaySchedule);

            if (!$todaySchedule || !is_array($todaySchedule)) {
                echo "  → Pas d'horaire défini pour aujourd'hui\n";
                return true;
            }

            $enabled = $todaySchedule['enabled'] ?? true;
            if (!$enabled) {
                echo "  → Jour désactivé\n";
                return false;
            }

            $start = $todaySchedule['start'] ?? null;
            $end = $todaySchedule['end'] ?? null;

            if ($start && $end) {
                return $inWindow($start, $end);
            }

            return true;
        }

        // Case 2: array of entries
        if (array_is_list($data)) {
            echo "Format tableau\n";
            foreach ($data as $entry) {
                if (!is_array($entry)) continue;
                $days = [];
                if (isset($entry['day'])) $days[] = (int)$entry['day'];
                if (isset($entry['days']) && is_array($entry['days'])) {
                    foreach ($entry['days'] as $d) { $days[] = (int)$d; }
                }
                if (empty($days)) $days = range(1,7);
                if (in_array($currentDay, $days, true)) {
                    if ($inWindow($entry['start'] ?? null, $entry['end'] ?? null)) return true;
                }
            }
            return false;
        }

        echo "Format non reconnu\n";
        return true;
    } catch (Exception $e) {
        echo "❌ Erreur: " . $e->getMessage() . "\n";
        return true;
    }
}

function getDayName($dayNumber) {
    $days = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return $days[$dayNumber] ?? 'Inconnu';
}
?>
