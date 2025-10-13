<?php
/**
 * Endpoint pour vérifier si l'utilisateur est toujours autorisé à être connecté
 * selon ses horaires de connexion (login_schedule)
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json; charset=UTF-8');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit();
}

require_once __DIR__ . '/config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();

    if (!$db) {
        throw new Exception('Erreur de connexion à la base de données');
    }

    // Récupérer le matricule ou user_id depuis les paramètres
    $userId = $_GET['user_id'] ?? $_POST['user_id'] ?? null;
    $matricule = $_GET['matricule'] ?? $_POST['matricule'] ?? null;

    if (!$userId && !$matricule) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'authorized' => false,
            'message' => 'user_id ou matricule requis'
        ]);
        exit();
    }

    // Récupérer l'utilisateur
    $query = "SELECT id, matricule, username, role, login_schedule, statut FROM users WHERE ";
    if ($userId) {
        $query .= "id = :identifier";
    } else {
        $query .= "matricule = :identifier";
    }
    $query .= " LIMIT 1";

    $stmt = $db->prepare($query);
    $identifier = $userId ?? $matricule;
    $stmt->bindParam(':identifier', $identifier);
    $stmt->execute();

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'authorized' => false,
            'message' => 'Utilisateur non trouvé'
        ]);
        exit();
    }

    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    // Vérifier le statut de l'utilisateur
    if ($user['statut'] !== 'actif') {
        echo json_encode([
            'success' => true,
            'authorized' => false,
            'message' => 'Compte désactivé',
            'reason' => 'account_disabled'
        ]);
        exit();
    }

    // Les superadmins ne sont pas soumis aux horaires
    $role = strtolower($user['role'] ?? 'agent');
    if ($role === 'superadmin') {
        echo json_encode([
            'success' => true,
            'authorized' => true,
            'message' => 'Accès autorisé (superadmin)'
        ]);
        exit();
    }

    // Vérifier les horaires si définis
    $scheduleJson = $user['login_schedule'] ?? null;
    if (empty($scheduleJson)) {
        // Pas d'horaire défini = accès autorisé
        echo json_encode([
            'success' => true,
            'authorized' => true,
            'message' => 'Accès autorisé (pas de restriction horaire)'
        ]);
        exit();
    }

    // Fonction de vérification des horaires (identique à AuthController)
    $isWithinSchedule = function($scheduleJson) {
        try {
            $data = is_array($scheduleJson) ? $scheduleJson : json_decode($scheduleJson, true);
            if (!$data) return true;

            $now = new DateTime('now');
            $currentDay = (int)$now->format('N'); // 1-7 (1=lundi)
            $currentTime = $now->format('H:i');

            $inWindow = function($start, $end) use ($currentTime) {
                if (!is_string($start) || !is_string($end)) return false;
                return $currentTime >= $start && $currentTime <= $end;
            };

            // Format associatif par jour numérique
            if (isset($data['1']) || isset($data['2']) || isset($data['3']) || isset($data['4']) || isset($data['5']) || isset($data['6']) || isset($data['7'])) {
                $windows = $data[(string)$currentDay] ?? [];
                if (!is_array($windows)) return true;
                foreach ($windows as $w) {
                    if ($inWindow($w['start'] ?? null, $w['end'] ?? null)) return true;
                }
                return false;
            }

            // Format associatif par nom de jour
            $dayNames = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
            if (isset($data['Lundi']) || isset($data['Mardi']) || isset($data['Mercredi']) || isset($data['Jeudi']) || isset($data['Vendredi']) || isset($data['Samedi']) || isset($data['Dimanche'])) {
                $todayName = $dayNames[$currentDay];
                $todaySchedule = $data[$todayName] ?? null;

                if (!$todaySchedule || !is_array($todaySchedule)) {
                    return true;
                }

                $enabled = $todaySchedule['enabled'] ?? true;
                if (!$enabled) {
                    return false;
                }

                $start = $todaySchedule['start'] ?? null;
                $end = $todaySchedule['end'] ?? null;

                if ($start && $end) {
                    return $inWindow($start, $end);
                }

                return true;
            }

            // Format array
            if (array_is_list($data)) {
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

            return true;
        } catch (Exception $e) {
            return true;
        }
    };

    $authorized = $isWithinSchedule($scheduleJson);

    echo json_encode([
        'success' => true,
        'authorized' => $authorized,
        'message' => $authorized ? 'Accès autorisé' : 'En dehors des heures de travail',
        'reason' => $authorized ? null : 'outside_schedule',
        'current_time' => date('H:i'),
        'current_day' => date('N')
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'authorized' => false,
        'message' => 'Erreur serveur: ' . $e->getMessage()
    ]);
}
?>
