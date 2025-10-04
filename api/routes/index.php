<?php
// Minimal router stub matching endpoints in lib/spec.md
// Note: This is a simple placeholder router. Replace with a real framework later.

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/../controllers/LogController.php';
require_once __DIR__ . '/../controllers/AuthController.php';
require_once __DIR__ . '/../controllers/UserController.php';
require_once __DIR__ . '/../controllers/VehiculeController.php';
require_once __DIR__ . '/../controllers/ParticulierController.php';
require_once __DIR__ . '/../controllers/EntrepriseController.php';
require_once __DIR__ . '/../controllers/ContraventionController.php';
require_once __DIR__ . '/../controllers/AccidentController.php';
require_once __DIR__ . '/../controllers/AvisRechercheController.php';
require_once __DIR__ . '/../controllers/PermisTemporaireController.php';
require_once __DIR__ . '/../controllers/ArrestationController.php';
require_once __DIR__ . '/../config/database.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$uri = $_SERVER['REQUEST_URI'] ?? '/';

// If behind subdir, strip query and normalize
$path = parse_url($uri, PHP_URL_PATH);
// If called as single entrypoint (index.php?route=/auth/login), prefer the explicit route
if (isset($_GET['route']) && is_string($_GET['route']) && $_GET['route'] !== '') {
    $path = $_GET['route'];
}

function json_ok($route, $extra = []) {
    echo json_encode(array_merge([
        'status' => 'ok',
        'route' => $route,
    ], $extra));
}

// Wrapper that logs activity then returns JSON
function json_ok_logged($route, $extra = []) {
    global $method;
    $ip = $_SERVER['REMOTE_ADDR'] ?? null;
    $ua = $_SERVER['HTTP_USER_AGENT'] ?? null;
    // Try to capture payload (JSON or POST)
    $raw = file_get_contents('php://input');
    $json = null;
    if ($raw) {
        $decoded = json_decode($raw, true);
        if (is_array($decoded)) { $json = $decoded; }
    }
    $params = $json ?? ($_POST ?? []);
    $username = $params['username'] ?? $params['matricule'] ?? null;
    LogController::record($username, $route, [
        'method' => $method,
        'params' => $params,
    ], $ip, $ua);
    json_ok($route, $extra);
}

// Helper to match dynamic segments
function path_match($pattern, $path, &$params = []) {
    $regex = preg_replace('#\{[^/]+\}#', '([^/]+)', $pattern);
    $regex = '#^' . $regex . '$#';
    if (preg_match($regex, $path, $m)) {
        array_shift($m);
        $params = $m;
        return true;
    }
    return false;
}


// Routes per spec.md
switch (true) {
    // Auth
    case $method === 'POST' && $path === '/auth/login':
        $raw = file_get_contents('php://input');
        $data = json_decode($raw, true) ?? [];
        $matricule = $data['matricule'] ?? '';
        $password = $data['password'] ?? '';
        
        if (empty($matricule) || empty($password)) {
            http_response_code(400);
            echo json_encode([
                'status' => 'error',
                'message' => 'Matricule et mot de passe requis',
                'errors' => [
                    'credentials' => ['Veuillez renseigner le matricule et le mot de passe']
                ]
            ]);
            break;
        }
        
        $authController = new AuthController();
        $auth_result = $authController->login($matricule, $password);
        
        if ($auth_result['success']) {
            json_ok_logged('POST /auth/login', [
                'token' => $auth_result['token'],
                'role' => $auth_result['role'],
                'username' => $auth_result['username'],
                'matricule' => $matricule,
                'first_connection' => $auth_result['first_connection'],
                'user' => $auth_result['user']
            ]);
        } else {
            http_response_code(401);
            echo json_encode([
                'status' => 'error',
                'message' => $auth_result['message'],
                'errors' => [
                    'credentials' => [$auth_result['message']]
                ]
            ]);
        }
        break;
        
    case $method === 'POST' && $path === '/auth/first-connection':
        $raw = file_get_contents('php://input');
        $data = json_decode($raw, true) ?? [];
        $userId = $data['user_id'] ?? '';
        $newPassword = $data['new_password'] ?? '';
        $confirmPassword = $data['confirm_password'] ?? '';
        
        if (empty($userId) || empty($newPassword) || empty($confirmPassword)) {
            http_response_code(400);
            echo json_encode([
                'status' => 'error',
                'message' => 'Tous les champs sont requis',
                'errors' => [
                    'fields' => ['Veuillez remplir tous les champs']
                ]
            ]);
            break;
        }
        
        $authController = new AuthController();
        $result = $authController->completeFirstConnection($userId, $newPassword, $confirmPassword);
        
        if ($result['success']) {
            json_ok_logged('POST /auth/first-connection', [
                'message' => $result['message']
            ]);
        } else {
            http_response_code(400);
            echo json_encode([
                'status' => 'error',
                'message' => $result['message'],
                'errors' => [
                    'password' => [$result['message']]
                ]
            ]);
        }
        break;
        
    case $method === 'POST' && $path === '/auth/change-password':
        json_ok_logged('POST /auth/change-password');
        break;
    case $method === 'POST' && $path === '/auth/reset-password':
        json_ok_logged('POST /auth/reset-password');
        break;

    // Users
    case $method === 'GET' && $path === '/users':
        $userController = new UserController();
        $result = $userController->getUsers();
        
        if ($result['success']) {
            json_ok_logged('GET /users', ['data' => $result['data']]);
        } else {
            http_response_code(500);
            echo json_encode([
                'status' => 'error',
                'message' => $result['message']
            ]);
        }
        break;
        
    case $method === 'POST' && $path === '/users/create':
        $raw = file_get_contents('php://input');
        $data = json_decode($raw, true) ?? [];
        
        // Validation des champs requis
        $required_fields = ['nom', 'matricule', 'poste', 'role', 'password'];
        $missing_fields = [];
        
        foreach ($required_fields as $field) {
            if (empty($data[$field])) {
                $missing_fields[] = $field;
            }
        }
        
        if (!empty($missing_fields)) {
            http_response_code(400);
            echo json_encode([
                'status' => 'error',
                'message' => 'Champs requis manquants: ' . implode(', ', $missing_fields),
                'errors' => [
                    'fields' => $missing_fields
                ]
            ]);
            break;
        }
        
        $userController = new UserController();
        
        
        // Préparer les données pour l'insertion
        $userData = [
            'matricule' => $data['matricule'],
            'username' => $data['nom'], // Le nom complet va dans username
            'telephone' => $data['telephone'] ?? '',
            'role' => $data['role'],
            'password' => $data['password'],
            'statut' => 'actif'
        ];
        
        // Ajouter les horaires si fournis
        if (isset($data['schedules'])) {
            $userData['login_schedule'] = json_encode($data['schedules']);
            error_log("Horaires JSON: " . $userData['login_schedule']);
        }
        
        error_log("Données préparées: " . json_encode($userData));
        
        $result = $userController->create($userData);
        
        if ($result['success']) {
            json_ok_logged('POST /users/create', [
                'message' => $result['message'],
                'id' => $result['id']
            ]);
        } else {
            http_response_code(400);
            echo json_encode([
                'status' => 'error',
                'message' => $result['message']
            ]);
        }
        break;
        
    case $method === 'POST' && path_match('/users/{id}/update', $path, $p):
        try {
            if (!isset($p[0])) { throw new Exception('ID utilisateur manquant'); }
            $id = (int)$p[0];
            $raw = file_get_contents('php://input');
            $data = json_decode($raw, true) ?? [];

            $allowed = ['username','matricule','poste','role','telephone','statut','password'];
            $sets = [];
            $params = [':id' => $id];

            foreach ($allowed as $field) {
                if (array_key_exists($field, $data)) {
                    if ($field === 'password') {
                        $sets[] = 'password = :password';
                        $params[':password'] = md5((string)$data['password']);
                        // force first_connection true on password reset
                        $sets[] = "first_connection = 'true'";
                    } else {
                        $sets[] = "$field = :$field";
                        $params[":$field"] = $data[$field];
                    }
                }
            }

            if (empty($sets)) { throw new Exception('Aucune donnée à mettre à jour'); }

            $sql = 'UPDATE users SET ' . implode(', ', $sets) . ', updated_at = NOW() WHERE id = :id';
            $database = new Database();
            $db = $database->getConnection();
            if (!$db) { throw new Exception('DB connection failed'); }
            $stmt = $db->prepare($sql);
            foreach ($params as $k => $v) { $stmt->bindValue($k, $v); }
            if (!$stmt->execute()) { throw new Exception('Mise à jour échouée'); }

            json_ok_logged('POST /users/{id}/update', ['id' => $id, 'updated' => true]);
        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
        }
        break;

    // Vehicule
    case $method === 'POST' && $path === '/vehicule/create':
        try {
            $database = new Database();
            $db = $database->getConnection();
            if (!$db) { throw new Exception('DB connection failed'); }

            // Ensure upload dirs
            $baseUploadDir = __DIR__ . '/../uploads';
            $vehDir = $baseUploadDir . '/vehicules';
            $cvDir = $baseUploadDir . '/contraventions';
            if (!is_dir($vehDir)) { @mkdir($vehDir, 0777, true); }
            if (!is_dir($cvDir)) { @mkdir($cvDir, 0777, true); }

            // Helper to process multi-files
            $saveFiles = function($fieldName, $targetDir) {
                $paths = [];
                if (!isset($_FILES[$fieldName])) return $paths;
                $files = $_FILES[$fieldName];
                $isMulti = is_array($files['name']);
                $count = $isMulti ? count($files['name']) : 1;
                for ($i = 0; $i < $count; $i++) {
                    $name = $isMulti ? $files['name'][$i] : $files['name'];
                    $tmp = $isMulti ? $files['tmp_name'][$i] : $files['tmp_name'];
                    $err = $isMulti ? $files['error'][$i] : $files['error'];
                    if ($err === UPLOAD_ERR_OK && is_uploaded_file($tmp)) {
                        $ext = pathinfo($name, PATHINFO_EXTENSION);
                        $safeName = uniqid('img_', true) . ($ext ? ('.' . preg_replace('/[^a-zA-Z0-9]/', '', $ext)) : '');
                        $destAbs = rtrim($targetDir, '/').'/'.$safeName;
                        if (move_uploaded_file($tmp, $destAbs)) {
                            // Public path hint (adjust base as needed)
                            $public = '/api/uploads/' . basename($targetDir) . '/' . $safeName;
                            $paths[] = $public;
                        }
                    }
                }
                return $paths;
            };

            $vehImages = $saveFiles('vehicle_images', $vehDir);
            $cvImages = $saveFiles('contravention_images', $cvDir);

            // Collect POST fields
            $f = function($k, $def = null) { return isset($_POST[$k]) && $_POST[$k] !== '' ? $_POST[$k] : $def; };

            // Insert into vehicule_plaque
            $stmt = $db->prepare("INSERT INTO vehicule_plaque (
                images, marque, modele, annee, couleur, numero_chassis, frontiere_entree, date_importation,
                plaque, plaque_valide_le, plaque_expire_le,
                nume_assurance, societe_assurance, date_valide_assurance, date_expire_assurance,
                genre, usage, numero_declaration, num_moteur, origine, source, annee_fab, annee_circ, type_em,
                en_circulation, created_at, updated_at
            ) VALUES (
                :images, :marque, :modele, :annee, :couleur, :numero_chassis, :frontiere_entree, :date_importation,
                :plaque, :plaque_valide_le, :plaque_expire_le,
                :nume_assurance, :societe_assurance, :date_valide_assurance, :date_expire_assurance,
                :genre, :usage, :numero_declaration, :num_moteur, :origine, :source, :annee_fab, :annee_circ, :type_em,
                :en_circulation, NOW(), NOW()
            )");

            $stmt->bindValue(':images', json_encode($vehImages));
            $stmt->bindValue(':marque', $f('marque'));
            $stmt->bindValue(':modele', $f('modele'));
            $stmt->bindValue(':annee', $f('annee'));
            $stmt->bindValue(':couleur', $f('couleur'));
            $stmt->bindValue(':numero_chassis', $f('numero_chassis'));
            $stmt->bindValue(':frontiere_entree', $f('frontiere_entree'));
            $stmt->bindValue(':date_importation', $f('date_importation'));
            $stmt->bindValue(':plaque', $f('plaque'));
            $stmt->bindValue(':plaque_valide_le', $f('plaque_valide_le'));
            $stmt->bindValue(':plaque_expire_le', $f('plaque_expire_le'));
            $stmt->bindValue(':nume_assurance', $f('nume_assurance'));
            $stmt->bindValue(':societe_assurance', $f('societe_assurance'));
            $stmt->bindValue(':date_valide_assurance', $f('date_valide_assurance'));
            $stmt->bindValue(':date_expire_assurance', $f('date_expire_assurance'));
            $stmt->bindValue(':genre', $f('genre'));
            $stmt->bindValue(':usage', $f('usage'));
            $stmt->bindValue(':numero_declaration', $f('numero_declaration'));
            $stmt->bindValue(':num_moteur', $f('num_moteur'));
            $stmt->bindValue(':origine', $f('origine'));
            $stmt->bindValue(':source', $f('source'));
            $stmt->bindValue(':annee_fab', $f('annee_fab'));
            $stmt->bindValue(':annee_circ', $f('annee_circ'));
            $stmt->bindValue(':type_em', $f('type_em'));
            $stmt->bindValue(':en_circulation', $f('en_circulation', 1));

            if (!$stmt->execute()) {
                throw new Exception('Insertion vehicule_plaque échouée');
            }

            $vehiculeId = $db->lastInsertId();

            $response = [
                'state' => true,
                'message' => 'Véhicule créé',
                'vehicle_id' => $vehiculeId,
                'vehicle_images' => $vehImages,
            ];

            // Optionally create contravention
            $withCv = $f('with_contravention', '0');
            if ($withCv === '1') {
                $cvStmt = $db->prepare("INSERT INTO contraventions (
                    dossier_id, type_dossier, date_infraction, lieu, type_infraction, description, reference_loi, amende, payed, photos, created_at
                ) VALUES (
                    :dossier_id, :type_dossier, :date_infraction, :lieu, :type_infraction, :description, :reference_loi, :amende, :payed, :photos, NOW()
                )");
                $cvStmt->bindValue(':dossier_id', $vehiculeId);
                $cvStmt->bindValue(':type_dossier', 'vehicule_plaque');
                $cvStmt->bindValue(':date_infraction', $f('cv_date_infraction'));
                $cvStmt->bindValue(':lieu', $f('cv_lieu'));
                $cvStmt->bindValue(':type_infraction', $f('cv_type_infraction'));
                $cvStmt->bindValue(':description', $f('cv_description'));
                $cvStmt->bindValue(':reference_loi', $f('cv_reference_loi'));
                $cvStmt->bindValue(':amende', $f('cv_amende'));
                $cvStmt->bindValue(':payed', $f('cv_payed', '0') === '1' ? 'oui' : 'non');
                $cvStmt->bindValue(':photos', json_encode($cvImages));
                if (!$cvStmt->execute()) {
                    throw new Exception('Insertion contravention échouée');
                }
                $response['contravention_id'] = $db->lastInsertId();
                $response['contravention_images'] = $cvImages;
            }

            // Log activity
            LogController::record(
                $_POST['username'] ?? null,
                'Création véhicule' . ($withCv === '1' ? ' + contravention' : ''),
                [
                    'vehicule_id' => $vehiculeId,
                    'fields' => $_POST,
                    'vehicule_images' => $vehImages,
                    'contravention_images' => $cvImages,
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );

            echo json_encode($response);
        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode([
                'state' => false,
                'message' => $e->getMessage(),
            ]);
        }
        break;
    case $method === 'POST' && $path === '/create-vehicule-with-contravention':
        try {
            $database = new Database();
            $db = $database->getConnection();
            if (!$db) { throw new Exception('DB connection failed'); }

            // Ensure upload dirs
            $baseUploadDir = __DIR__ . '/../uploads';
            $vehDir = $baseUploadDir . '/vehicules';
            $cvDir = $baseUploadDir . '/contraventions';
            if (!is_dir($vehDir)) { @mkdir($vehDir, 0777, true); }
            if (!is_dir($cvDir)) { @mkdir($cvDir, 0777, true); }

            // Helper to process multi-files
            $saveFiles = function($fieldName, $targetDir) {
                $paths = [];
                if (!isset($_FILES[$fieldName])) return $paths;
                $files = $_FILES[$fieldName];
                $isMulti = is_array($files['name']);
                $count = $isMulti ? count($files['name']) : 1;
                for ($i = 0; $i < $count; $i++) {
                    $name = $isMulti ? $files['name'][$i] : $files['name'];
                    $tmp = $isMulti ? $files['tmp_name'][$i] : $files['tmp_name'];
                    $err = $isMulti ? $files['error'][$i] : $files['error'];
                    if ($err === UPLOAD_ERR_OK && is_uploaded_file($tmp)) {
                        $ext = pathinfo($name, PATHINFO_EXTENSION);
                        $safeName = uniqid('img_', true) . ($ext ? ('.' . preg_replace('/[^a-zA-Z0-9]/', '', $ext)) : '');
                        $destAbs = rtrim($targetDir, '/').'/'.$safeName;
                        if (move_uploaded_file($tmp, $destAbs)) {
                            // Public path hint (adjust base as needed)
                            $public = '/api/uploads/' . basename($targetDir) . '/' . $safeName;
                            $paths[] = $public;
                        }
                    }
                }
                return $paths;
            };

            $vehImages = $saveFiles('vehicle_images', $vehDir);
            $cvImages = $saveFiles('contravention_images', $cvDir);

            // Collect POST fields
            $f = function($k, $def = null) { return isset($_POST[$k]) && $_POST[$k] !== '' ? $_POST[$k] : $def; };

            // Insert into vehicule_plaque
            $stmt = $db->prepare("INSERT INTO vehicule_plaque (
                images, marque, modele, annee, couleur, numero_chassis, frontiere_entree, date_importation,
                plaque, plaque_valide_le, plaque_expire_le,
                nume_assurance, societe_assurance, date_valide_assurance, date_expire_assurance,
                genre, usage, numero_declaration, num_moteur, origine, source, annee_fab, annee_circ, type_em,
                en_circulation, created_at, updated_at
            ) VALUES (
                :images, :marque, :modele, :annee, :couleur, :numero_chassis, :frontiere_entree, :date_importation,
                :plaque, :plaque_valide_le, :plaque_expire_le,
                :nume_assurance, :societe_assurance, :date_valide_assurance, :date_expire_assurance,
                :genre, :usage, :numero_declaration, :num_moteur, :origine, :source, :annee_fab, :annee_circ, :type_em,
                :en_circulation, NOW(), NOW()
            )");

            $stmt->bindValue(':images', json_encode($vehImages));
            $stmt->bindValue(':marque', $f('marque'));
            $stmt->bindValue(':modele', $f('modele'));
            $stmt->bindValue(':annee', $f('annee'));
            $stmt->bindValue(':couleur', $f('couleur'));
            $stmt->bindValue(':numero_chassis', $f('numero_chassis'));
            $stmt->bindValue(':frontiere_entree', $f('frontiere_entree'));
            $stmt->bindValue(':date_importation', $f('date_importation'));
            $stmt->bindValue(':plaque', $f('plaque'));
            $stmt->bindValue(':plaque_valide_le', $f('plaque_valide_le'));
            $stmt->bindValue(':plaque_expire_le', $f('plaque_expire_le'));
            $stmt->bindValue(':nume_assurance', $f('nume_assurance'));
            $stmt->bindValue(':societe_assurance', $f('societe_assurance'));
            $stmt->bindValue(':date_valide_assurance', $f('date_valide_assurance'));
            $stmt->bindValue(':date_expire_assurance', $f('date_expire_assurance'));
            $stmt->bindValue(':genre', $f('genre'));
            $stmt->bindValue(':usage', $f('usage'));
            $stmt->bindValue(':numero_declaration', $f('numero_declaration'));
            $stmt->bindValue(':num_moteur', $f('num_moteur'));
            $stmt->bindValue(':origine', $f('origine'));
            $stmt->bindValue(':source', $f('source'));
            $stmt->bindValue(':annee_fab', $f('annee_fab'));
            $stmt->bindValue(':annee_circ', $f('annee_circ'));
            $stmt->bindValue(':type_em', $f('type_em'));
            $stmt->bindValue(':en_circulation', $f('en_circulation', 1));

            if (!$stmt->execute()) {
                throw new Exception('Insertion vehicule_plaque échouée');
            }

            $vehiculeId = $db->lastInsertId();

            $response = [
                'state' => true,
                'message' => 'Véhicule créé',
                'vehicle_id' => $vehiculeId,
                'vehicle_images' => $vehImages,
            ];

            // Optionally create contravention
            $withCv = $f('with_contravention', '0');
            if ($withCv === '1') {
                // Map fields to contraventions schema
                $cvStmt = $db->prepare("INSERT INTO contraventions (
                    dossier_id, type_dossier, date_infraction, lieu, type_infraction, description, reference_loi, amende, payed, photos, created_at
                ) VALUES (
                    :dossier_id, :type_dossier, :date_infraction, :lieu, :type_infraction, :description, :reference_loi, :amende, :payed, :photos, NOW()
                )");
                $cvStmt->bindValue(':dossier_id', $vehiculeId);
                $cvStmt->bindValue(':type_dossier', 'vehicule_plaque');
                $cvStmt->bindValue(':date_infraction', $f('cv_date_infraction'));
                $cvStmt->bindValue(':lieu', $f('cv_lieu'));
                $cvStmt->bindValue(':type_infraction', $f('cv_type_infraction'));
                $cvStmt->bindValue(':description', $f('cv_description'));
                $cvStmt->bindValue(':reference_loi', $f('cv_reference_loi'));
                $cvStmt->bindValue(':amende', $f('cv_amende'));
                $cvStmt->bindValue(':payed', $f('cv_payed', '0') === '1' ? 'oui' : 'non');
                $cvStmt->bindValue(':photos', json_encode($cvImages));
                if (!$cvStmt->execute()) {
                    throw new Exception('Insertion contravention échouée');
                }
                $response['contravention_id'] = $db->lastInsertId();
                $response['contravention_images'] = $cvImages;
            }

            // Log activity
            LogController::record(
                $_POST['username'] ?? null,
                'Création véhicule' . ($withCv === '1' ? ' + contravention' : ''),
                [
                    'vehicule_id' => $vehiculeId,
                    'fields' => $_POST,
                    'vehicule_images' => $vehImages,
                    'contravention_images' => $cvImages,
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );

            echo json_encode($response);
        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode([
                'state' => false,
                'message' => $e->getMessage(),
            ]);
        }
        break;
    case $method === 'POST' && path_match('/vehicule/{id}/update', $path, $p):
        json_ok_logged('POST /vehicule/{id}/update', ['id' => $p[0] ?? null]);
        break;
    case $method === 'POST' && path_match('/vehicule/{id}/retirer', $path, $p):
        json_ok_logged('POST /vehicule/{id}/retirer', ['id' => $p[0] ?? null]);
        break;
    case $method === 'POST' && path_match('/vehicule/{id}/remettre', $path, $p):
        json_ok_logged('POST /vehicule/{id}/remettre', ['id' => $p[0] ?? null]);
        break;
    // Vehicule by internal ID (numeric)
    case $method === 'GET' && path_match('/vehicule/{id}', $path, $p):
        if (isset($p[0]) && preg_match('/^\d+$/', $p[0])) {
            try {
                $database = new Database();
                $db = $database->getConnection();
                if (!$db) { throw new Exception('DB connection failed'); }
                $stmt = $db->prepare("SELECT * FROM vehicule_plaque WHERE id = :id LIMIT 1");
                $stmt->bindValue(':id', (int)$p[0], PDO::PARAM_INT);
                $stmt->execute();
                $veh = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($veh) {
                    echo json_encode(['state' => true, 'data' => $veh]);
                } else {
                    http_response_code(404);
                    echo json_encode(['state' => false, 'message' => 'Véhicule introuvable']);
                }
            } catch (Exception $e) {
                http_response_code(500);
                echo json_encode(['state' => false, 'message' => $e->getMessage()]);
            }
            break;
        }
        // If not numeric, let next route handle plaque
        // no break here
    case $method === 'GET' && path_match('/vehicule/{plaque}', $path, $p):
        json_ok_logged('GET /vehicule/{plaque}', ['plaque' => $p[0] ?? null]);
        break;

    // Particulier
    case $method === 'POST' && $path === '/particulier/create':
        json_ok_logged('POST /particulier/create');
        break;
    case $method === 'POST' && path_match('/particulier/{id}/update', $path, $p):
        json_ok_logged('POST /particulier/{id}/update', ['id' => $p[0] ?? null]);
        break;
    case $method === 'GET' && path_match('/particulier/{id}', $path, $p):
        json_ok_logged('GET /particulier/{id}', ['id' => $p[0] ?? null]);
        break;

    // Entreprise
    case $method === 'POST' && $path === '/entreprise/create':
        json_ok_logged('POST /entreprise/create');
        break;
    case $method === 'POST' && path_match('/entreprise/{id}/update', $path, $p):
        json_ok_logged('POST /entreprise/{id}/update', ['id' => $p[0] ?? null]);
        break;
    case $method === 'GET' && path_match('/entreprise/{id}', $path, $p):
        json_ok_logged('GET /entreprise/{id}', ['id' => $p[0] ?? null]);
        break;

    // Contravention
    case $method === 'POST' && $path === '/contravention/create':
        json_ok_logged('POST /contravention/create');
        break;
    case $method === 'GET' && path_match('/contravention/{id}', $path, $p):
        json_ok_logged('GET /contravention/{id}', ['id' => $p[0] ?? null]);
        break;
    case $method === 'GET' && path_match('/contravention/{id}/pdf', $path, $p):
        json_ok_logged('GET /contravention/{id}/pdf', ['id' => $p[0] ?? null]);
        break;

    // Accident
    case $method === 'POST' && $path === '/accident/create':
        json_ok_logged('POST /accident/create');
        break;
    case $method === 'POST' && path_match('/accident/{id}/update', $path, $p):
        json_ok_logged('POST /accident/{id}/update', ['id' => $p[0] ?? null]);
        break;
    case $method === 'GET' && path_match('/accident/{id}', $path, $p):
        json_ok_logged('GET /accident/{id}', ['id' => $p[0] ?? null]);
        break;

    // Avis de recherche
    case $method === 'POST' && $path === '/avis-recherche/create':
        json_ok_logged('POST /avis-recherche/create');
        break;
    case $method === 'POST' && path_match('/avis-recherche/{id}/close', $path, $p):
        json_ok_logged('POST /avis-recherche/{id}/close', ['id' => $p[0] ?? null]);
        break;
    case $method === 'GET' && path_match('/avis-recherche/{id}', $path, $p):
        json_ok_logged('GET /avis-recherche/{id}', ['id' => $p[0] ?? null]);
        break;

    // Permis temporaire
    case $method === 'POST' && $path === '/permis-temporaire/create':
        json_ok_logged('POST /permis-temporaire/create');
        break;
    case $method === 'GET' && path_match('/permis-temporaire/{id}/pdf', $path, $p):
        json_ok_logged('GET /permis-temporaire/{id}/pdf', ['id' => $p[0] ?? null]);
        break;

    // Arrestation
    case $method === 'POST' && $path === '/arrestation/create':
        json_ok_logged('POST /arrestation/create');
        break;
    case $method === 'POST' && path_match('/arrestation/{id}/release', $path, $p):
        json_ok_logged('POST /arrestation/{id}/release', ['id' => $p[0] ?? null]);
        break;
    case $method === 'GET' && path_match('/particulier/{id}/arrestations', $path, $p):
        json_ok_logged('GET /particulier/{id}/arrestations', ['id' => $p[0] ?? null, 'data' => []]);
        break;

    // Logs (récupérés de la table activites)
    case $method === 'GET' && $path === '/logs':
        $logController = new LogController();
        
        // Debug
        error_log("=== GET /logs ===");
        error_log("Paramètres GET: " . json_encode($_GET));
        
        // Récupérer les paramètres de requête
        $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
        $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
        $username = $_GET['username'] ?? null;
        $action = $_GET['action'] ?? null;
        
        error_log("Paramètres traités - limit: $limit, offset: $offset, username: $username, action: $action");
        
        $result = $logController->getLogs($limit, $offset, $username, $action);
        
        error_log("Résultat LogController: " . json_encode($result));
        
        if ($result['success']) {
            // Log de la consultation des activités
            LogController::record(
                'system',
                'Consultation du rapport d\'activités',
                [
                    'filters' => [
                        'limit' => $limit,
                        'offset' => $offset,
                        'username' => $username,
                        'action' => $action
                    ],
                    'results_count' => count($result['data'] ?? [])
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );
            
            // Return the processed data directly
            echo json_encode(array_merge([
                'status' => 'ok',
                'route' => 'GET /logs',
            ], $result));
        } else {
            http_response_code(500);
            echo json_encode([
                'status' => 'error',
                'message' => $result['message']
            ]);
        }
        break;
        
    case $method === 'GET' && $path === '/logs/stats':
        $logController = new LogController();
        $days = isset($_GET['days']) ? (int)$_GET['days'] : 30;
        
        $result = $logController->getStats($days);
        
        if ($result['success']) {
            // Log de la consultation des statistiques
            LogController::record(
                'system',
                'Consultation des statistiques d\'activités',
                [
                    'period_days' => $days,
                    'stats_count' => count($result['data'] ?? [])
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );
            
            json_ok_logged('GET /logs/stats', $result);
        } else {
            http_response_code(500);
            echo json_encode([
                'status' => 'error',
                'message' => $result['message']
            ]);
        }
        break;
        
    case $method === 'POST' && $path === '/logs/add':
        $raw = file_get_contents('php://input');
        $data = json_decode($raw, true) ?? [];
        
        $logController = new LogController();
        $result = $logController->addLog($data);
        
        if ($result['success']) {
            json_ok_logged('POST /logs/add', $result);
        } else {
            http_response_code(400);
            echo json_encode([
                'status' => 'error',
                'message' => $result['message']
            ]);
        }
        break;
        
    // Documentation de la base de données
    case $method === 'GET' && $path === '/schema':
        try {
            $database = new Database();
            $db = $database->getConnection();
            
            if (!$db) {
                throw new Exception("Erreur de connexion à la base de données");
            }
            
            // Obtenir toutes les tables
            $stmt = $db->query("SHOW TABLES");
            $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
            
            $schema = [];
            foreach ($tables as $table) {
                $stmt = $db->query("DESCRIBE $table");
                $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                $schema[$table] = [
                    'columns' => [],
                    'primary_key' => null
                ];
                
                foreach ($columns as $column) {
                    $schema[$table]['columns'][$column['Field']] = [
                        'type' => $column['Type'],
                        'nullable' => $column['Null'] === 'YES',
                        'default' => $column['Default'],
                        'extra' => $column['Extra']
                    ];
                    
                    if ($column['Key'] === 'PRI') {
                        $schema[$table]['primary_key'] = $column['Field'];
                    }
                }
            }
            
            json_ok('GET /schema', ['schema' => $schema]);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 'error',
                'message' => 'Erreur lors de la récupération du schéma: ' . $e->getMessage()
            ]);
        }
        break;

    default:
        http_response_code(404);
        echo json_encode(['status' => 'error', 'message' => 'Not Found', 'path' => $path, 'method' => $method]);
        break;
}
?>
