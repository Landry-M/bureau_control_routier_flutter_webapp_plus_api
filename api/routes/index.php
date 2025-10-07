<?php
// Minimal router stub matching endpoints in lib/spec.md
// Note: This is a simple placeholder router. Replace with a real framework later.

// Configuration CORS pour accepter toutes les origines
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin, X-Auth-Token, X-API-Key');
header('Access-Control-Max-Age: 86400'); // Cache preflight pour 24h
header('Content-Type: application/json; charset=utf-8');

// Gestion des requêtes OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    // Répondre immédiatement aux requêtes preflight
    http_response_code(200);
    exit;
}

// Debug CORS - optionnel
if (isset($_GET['debug_cors'])) {
    error_log("CORS DEBUG - Origin: " . ($_SERVER['HTTP_ORIGIN'] ?? 'none'));
    error_log("CORS DEBUG - Method: " . ($_SERVER['REQUEST_METHOD'] ?? 'none'));
    error_log("CORS DEBUG - Headers: " . json_encode(getallheaders()));
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
require_once __DIR__ . '/../controllers/HistoriqueRetraitPlaqueController.php';
require_once __DIR__ . '/../controllers/ParticulierVehiculeController.php';
require_once __DIR__ . '/../controllers/EntrepriseVehiculeController.php';
require_once __DIR__ . '/../config/database.php';

function getDbConnection() {
    $database = new Database();
    return $database->getConnection();
}

// Fonction pour générer un numéro de plaque temporaire au format PT-XXXXXX
function generatePlaqueTemporaireNumber() {
    $pdo = getDbConnection();
    
    // Compter les plaques temporaires existantes cette année
    $year = date('Y');
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM permis_temporaire WHERE numero LIKE :pattern AND YEAR(created_at) = :year");
    $pattern = 'PT-%';
    $stmt->bindParam(':pattern', $pattern);
    $stmt->bindParam(':year', $year);
    $stmt->execute();
    
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    $count = ($result['count'] ?? 0) + 1;
    
    return 'PT-' . str_pad($count, 6, '0', STR_PAD_LEFT);
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$uri = $_SERVER['REQUEST_URI'] ?? '/';

// If behind subdir, strip query and normalize
$path = parse_url($uri, PHP_URL_PATH);

// Remove /api/routes/index.php prefix if present
if (strpos($path, '/api/routes/index.php') === 0) {
    $path = substr($path, strlen('/api/routes/index.php'));
}

// Ensure we strip any remaining query parameters from path
$path = strtok($path, '?');

// If called as single entrypoint (index.php?route=/auth/login), prefer the explicit route
if (isset($_GET['route']) && is_string($_GET['route']) && $_GET['route'] !== '') {
    $path = $_GET['route'];
} elseif (isset($_POST['route']) && is_string($_POST['route']) && $_POST['route'] !== '') {
    $path = $_POST['route'];
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

            $allowed = ['username','matricule','poste','role','telephone','statut','password','login_schedule'];
            $sets = [];
            $params = [':id' => $id];

            foreach ($allowed as $field) {
                if (array_key_exists($field, $data)) {
                    if ($field === 'password') {
                        $sets[] = 'password = :password';
                        $params[':password'] = md5((string)$data['password']);
                        // force first_connection true on password reset
                        $sets[] = "first_connection = 'true'";
                    } elseif ($field === 'login_schedule') {
                        $sets[] = 'login_schedule = :login_schedule';
                        $val = $data['login_schedule'];
                        if (is_array($val)) { $val = json_encode($val); }
                        $params[':login_schedule'] = $val;
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

    case $method === 'POST' && path_match('/users/{id}/delete', $path, $p):
        try {
            if (!isset($p[0])) { throw new Exception('ID utilisateur manquant'); }
            $id = (int)$p[0];
            $userController = new UserController();
            $result = $userController->delete($id);
            if ($result['success']) {
                json_ok_logged('POST /users/{id}/delete', ['id' => $id, 'deleted' => true, 'message' => $result['message']]);
            } else {
                http_response_code(400);
                echo json_encode(['status' => 'error', 'message' => $result['message']]);
            }
        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        break;

    // Vehicule
    case $method === 'POST' && $path === '/vehicule/create':
        try {
            require_once __DIR__ . '/../controllers/VehiculeController.php';
            
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

            // Use VehiculeController
            $vehiculeController = new VehiculeController();
            $result = $vehiculeController->createWithDetails($_POST, $vehImages, $cvImages);
            
            if (!$result['success']) {
                throw new Exception($result['message']);
            }

            $response = [
                'state' => true,
                'message' => $result['message'],
                'vehicle_id' => $result['id'],
                'vehicle_images' => $vehImages,
            ];

            if (isset($_POST['with_contravention']) && $_POST['with_contravention'] === '1') {
                $response['contravention_images'] = $cvImages;
            }

            // Log activity
            $withCv = isset($_POST['with_contravention']) && $_POST['with_contravention'] === '1';
            LogController::record(
                $_POST['username'] ?? null,
                'Création véhicule' . ($withCv ? ' + contravention' : ''),
                [
                    'vehicule_id' => $result['id'],
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
            require_once __DIR__ . '/../controllers/VehiculeController.php';
            
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

            // Use VehiculeController with plaque uniqueness check
            $vehiculeController = new VehiculeController();
            $result = $vehiculeController->createWithDetails($_POST, $vehImages, $cvImages);
            
            if (!$result['success']) {
                throw new Exception($result['message']);
            }

            // Log activity
            LogController::record(
                $_POST['username'] ?? null,
                'Création véhicule' . (isset($_POST['with_contravention']) && $_POST['with_contravention'] === '1' ? ' + contravention' : ''),
                [
                    'vehicule_id' => $result['id'],
                    'fields' => $_POST,
                    'vehicule_images' => $vehImages,
                    'contravention_images' => $cvImages,
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );

            echo json_encode([
                'state' => true,
                'message' => $result['message'],
                'vehicle_id' => $result['id'],
                'vehicle_images' => $vehImages,
                'contravention_images' => $cvImages,
            ]);
        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode([
                'state' => false,
                'message' => $e->getMessage(),
            ]);
        }
        break;
    case $method === 'POST' && path_match('/vehicule/{id}/update', $path, $p):
        try {
            $vehiculeId = $p[0] ?? null;
            if (!$vehiculeId || !is_numeric($vehiculeId)) {
                throw new Exception('ID véhicule invalide');
            }

            // Ensure upload dir
            $baseUploadDir = __DIR__ . '/../uploads';
            $vehDir = $baseUploadDir . '/vehicules';
            if (!is_dir($vehDir)) { @mkdir($vehDir, 0777, true); }

            // Handle file uploads
            $saveFiles = function($fieldName, $uploadDir) {
                $savedFiles = [];
                if (isset($_FILES[$fieldName]) && is_array($_FILES[$fieldName]['name'])) {
                    foreach ($_FILES[$fieldName]['name'] as $index => $name) {
                        if ($_FILES[$fieldName]['error'][$index] === UPLOAD_ERR_OK) {
                            $ext = pathinfo($name, PATHINFO_EXTENSION);
                            $filename = 'img_' . uniqid() . '.' . $ext;
                            $destination = $uploadDir . '/' . $filename;
                            if (move_uploaded_file($_FILES[$fieldName]['tmp_name'][$index], $destination)) {
                                $savedFiles[] = '/api/uploads/vehicules/' . $filename;
                            }
                        }
                    }
                }
                return $savedFiles;
            };

            $vehImages = $saveFiles('vehicule_images', $vehDir);

            // Use VehiculeController
            $vehiculeController = new VehiculeController();
            $result = $vehiculeController->update((int)$vehiculeId, $_POST, $vehImages);
            
            if (!$result['success']) {
                throw new Exception($result['message']);
            }

            // Log de l'activité
            LogController::record(
                $_POST['username'] ?? null,
                'Modification véhicule',
                [
                    'vehicule_id' => $vehiculeId,
                    'fields' => $_POST,
                    'vehicule_images' => $vehImages,
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );

            echo json_encode([
                'success' => true,
                'message' => $result['message']
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;
    case $method === 'POST' && path_match('/vehicule/{id}/retirer', $path, $p):
        json_ok_logged('POST /vehicule/{id}/retirer', ['id' => $p[0] ?? null]);
        break;
    case $method === 'POST' && path_match('/vehicule/{id}/retirer-plaque', $path, $p):
        try {
            $vehiculeId = $p[0] ?? null;
            if (!$vehiculeId || !is_numeric($vehiculeId)) {
                throw new Exception('ID véhicule invalide');
            }

            // Lire les données JSON du body
            $data = json_decode(file_get_contents('php://input'), true) ?? [];
            
            $username = $data['username'] ?? $_POST['username'] ?? null;
            $dateRetrait = $data['date_retrait'] ?? $_POST['date_retrait'] ?? null;
            $motif = $data['motif'] ?? $_POST['motif'] ?? null;
            $observations = $data['observations'] ?? $_POST['observations'] ?? null;

            // Log pour déboguer
            error_log("Retrait plaque - Username: " . ($username ?? 'NULL') . ", Motif: " . ($motif ?? 'NULL') . ", Observations: " . ($observations ?? 'NULL'));

            $vehiculeController = new VehiculeController();
            $result = $vehiculeController->retirerPlaque((int)$vehiculeId, $username, $dateRetrait, $motif, $observations);
            
            if (!$result['success']) {
                throw new Exception($result['message']);
            }

            // Log de l'activité
            LogController::record(
                $username,
                'Retrait de plaque',
                [
                    'vehicule_id' => $vehiculeId,
                    'ancienne_plaque' => $result['ancienne_plaque'] ?? null,
                    'action' => 'retrait_plaque',
                    'motif' => $motif
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );

            echo json_encode([
                'success' => true,
                'message' => $result['message'],
                'ancienne_plaque' => $result['ancienne_plaque'] ?? null
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;
    
    // Récupérer l'historique des retraits de plaques pour un véhicule
    case $method === 'GET' && path_match('/vehicule/{id}/historique-retraits', $path, $p):
        try {
            $vehiculeId = $p[0] ?? null;
            if (!$vehiculeId || !is_numeric($vehiculeId)) {
                throw new Exception('ID véhicule invalide');
            }

            $historiqueController = new HistoriqueRetraitPlaqueController();
            $result = $historiqueController->getByVehiculeId((int)$vehiculeId);
            
            // Log de la consultation
            LogController::record(
                $_GET['username'] ?? 'system',
                'Consultation historique retraits plaque',
                [
                    'vehicule_id' => $vehiculeId,
                    'total_retraits' => count($result['data'] ?? [])
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );

            echo json_encode($result);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ]);
        }
        break;
    
    // Association particulier-véhicule
    case $method === 'POST' && $path === '/particulier-vehicule/associer':
        try {
            // Lire les données JSON du body
            $data = json_decode(file_get_contents('php://input'), true) ?? [];
            
            $particulierId = $data['particulier_id'] ?? null;
            $vehiculePlaqueId = $data['vehicule_plaque_id'] ?? null;
            $role = $data['role'] ?? 'proprietaire';
            $dateAssoc = $data['date_assoc'] ?? null;
            $notes = $data['notes'] ?? null;
            $username = $data['username'] ?? null;
            $force = $data['force'] ?? false; // Nouveau paramètre pour forcer l'association
            
            if (!$particulierId || !$vehiculePlaqueId) {
                throw new Exception('ID particulier et ID véhicule requis');
            }
            
            $controller = new ParticulierVehiculeController();
            $result = $controller->associer(
                $particulierId,
                $vehiculePlaqueId,
                $role,
                $dateAssoc,
                $notes,
                $username,
                $force
            );
            
            // Si requiresConfirmation, retourner la réponse sans erreur
            if (isset($result['requiresConfirmation']) && $result['requiresConfirmation']) {
                echo json_encode($result);
                break;
            }
            
            if (!$result['success']) {
                throw new Exception($result['message']);
            }
            
            // Log de l'activité
            LogController::record(
                $username,
                'Association particulier-véhicule',
                [
                    'particulier_id' => $particulierId,
                    'vehicule_plaque_id' => $vehiculePlaqueId,
                    'role' => $role,
                    'forced' => $force,
                    'action' => 'associer'
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );
            
            echo json_encode($result);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;
    
    // Association entreprise-véhicule
    case $method === 'POST' && $path === '/entreprise-vehicule/associer':
        try {
            // Lire les données JSON du body
            $data = json_decode(file_get_contents('php://input'), true) ?? [];
            
            $entrepriseId = $data['entreprise_id'] ?? null;
            $vehiculePlaqueId = $data['vehicule_plaque_id'] ?? null;
            $dateAssoc = $data['date_assoc'] ?? null;
            $notes = $data['notes'] ?? null;
            $username = $data['username'] ?? null;
            $force = $data['force'] ?? false; // Nouveau paramètre pour forcer l'association
            
            if (!$entrepriseId || !$vehiculePlaqueId) {
                throw new Exception('ID entreprise et ID véhicule requis');
            }
            
            $controller = new EntrepriseVehiculeController();
            $result = $controller->associer(
                $entrepriseId,
                $vehiculePlaqueId,
                $dateAssoc,
                $notes,
                $username,
                $force
            );
            
            // Si requiresConfirmation, retourner la réponse sans erreur
            if (isset($result['requiresConfirmation']) && $result['requiresConfirmation']) {
                echo json_encode($result);
                break;
            }
            
            if (!$result['success']) {
                throw new Exception($result['message']);
            }
            
            // Log de l'activité
            LogController::record(
                $username,
                'Association entreprise-véhicule',
                [
                    'entreprise_id' => $entrepriseId,
                    'vehicule_plaque_id' => $vehiculePlaqueId,
                    'forced' => $force,
                    'action' => 'associer'
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );
            
            echo json_encode($result);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;
    
    // Récupérer le propriétaire actuel d'un véhicule
    case $method === 'GET' && path_match('/vehicule/{id}/current-owner', $path, $p):
        try {
            $vehiculeId = $p[0] ?? null;
            if (!$vehiculeId || !is_numeric($vehiculeId)) {
                throw new Exception('ID véhicule invalide');
            }
            
            $controller = new ParticulierVehiculeController();
            $result = $controller->getCurrentOwner((int)$vehiculeId);
            
            if (!$result['success']) {
                throw new Exception($result['message']);
            }
            
            echo json_encode($result);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;
    
    case $method === 'POST' && path_match('/vehicule/{id}/retirer-circulation', $path, $p):
        try {
            $vehiculeId = $p[0] ?? null;
            if (!$vehiculeId || !is_numeric($vehiculeId)) {
                throw new Exception('ID véhicule invalide');
            }

            $vehiculeController = new VehiculeController();
            $result = $vehiculeController->retirerDeCirculation((int)$vehiculeId);
            
            if (!$result['success']) {
                throw new Exception($result['message']);
            }

            // Log de l'activité
            LogController::record(
                $_POST['username'] ?? null,
                'Retrait véhicule de la circulation',
                [
                    'vehicule_id' => $vehiculeId,
                    'plaque' => $result['plaque'] ?? null,
                    'action' => 'retrait_circulation'
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );

            echo json_encode([
                'success' => true,
                'message' => $result['message'],
                'plaque' => $result['plaque'] ?? null
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
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

    // Liste des véhicules avec pagination
    case $method === 'GET' && $path === '/vehicules':
        try {
            $page = max(1, (int)($_GET['page'] ?? 1));
            $limit = max(1, min(100, (int)($_GET['limit'] ?? 20)));
            $search = $_GET['search'] ?? '';
            $offset = ($page - 1) * $limit;
            
            $database = new Database();
            $db = $database->getConnection();
            if (!$db) { 
                throw new Exception('DB connection failed'); 
            }
            
            // Construire la requête avec recherche optionnelle
            $whereClause = '';
            $params = [];
            if (!empty($search)) {
                $whereClause = 'WHERE plaque LIKE :search OR marque LIKE :search OR modele LIKE :search OR proprietaire LIKE :search';
                $params[':search'] = '%' . $search . '%';
            }
            
            // Compter le total
            $countStmt = $db->prepare("SELECT COUNT(*) as total FROM vehicule_plaque $whereClause");
            foreach ($params as $key => $value) {
                $countStmt->bindValue($key, $value);
            }
            $countStmt->execute();
            $totalCount = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
            
            // Récupérer les données paginées
            $stmt = $db->prepare("SELECT * FROM vehicule_plaque $whereClause ORDER BY id DESC LIMIT :limit OFFSET :offset");
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
            $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
            $stmt->execute();
            
            $vehicules = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Log de la consultation des véhicules
            LogController::record(
                $_GET['username'] ?? 'system',
                'Consultation liste véhicules',
                [
                    'page' => $page,
                    'limit' => $limit,
                    'search' => $search,
                    'total_results' => $totalCount
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );
            
            echo json_encode([
                'success' => true,
                'data' => $vehicules,
                'pagination' => [
                    'page' => $page,
                    'limit' => $limit,
                    'total' => $totalCount,
                    'pages' => ceil($totalCount / $limit)
                ]
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'error' => 'Erreur lors de la récupération des véhicules: ' . $e->getMessage()
            ]);
        }
        break;

    // Recherche globale de véhicules (pour la barre de recherche)
    case $method === 'GET' && $path === '/vehicules/search':
        try {
            $query = $_GET['q'] ?? '';
            
            if (empty($query)) {
                echo json_encode([
                    'ok' => true,
                    'items' => [],
                    'data' => []
                ]);
                break;
            }
            
            $database = new Database();
            $db = $database->getConnection();
            if (!$db) { 
                throw new Exception('DB connection failed'); 
            }
            
            // Recherche dans plusieurs champs
            $searchPattern = '%' . $query . '%';
            $stmt = $db->prepare("
                SELECT * FROM vehicule_plaque 
                WHERE plaque LIKE :search 
                   OR marque LIKE :search 
                   OR modele LIKE :search 
                   OR couleur LIKE :search
                   OR proprietaire LIKE :search
                   OR CAST(annee AS CHAR) LIKE :search
                ORDER BY id DESC 
                LIMIT 50
            ");
            $stmt->bindValue(':search', $searchPattern);
            $stmt->execute();
            
            $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Log de la recherche
            LogController::record(
                $_GET['username'] ?? 'system',
                'Recherche globale véhicules',
                [
                    'query' => $query,
                    'nb_results' => count($results)
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );
            
            echo json_encode([
                'ok' => true,
                'items' => $results,
                'data' => $results
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'ok' => false,
                'error' => 'Erreur lors de la recherche: ' . $e->getMessage()
            ]);
        }
        break;

    // Création rapide de véhicule (pour les accidents)
    case $method === 'POST' && $path === '/vehicule/quick-create':
        try {
            require_once __DIR__ . '/../controllers/VehiculeController.php';
            
            $vehiculeController = new VehiculeController();
            
            // Récupérer les données
            $plaque = $_POST['plaque'] ?? '';
            $marque = $_POST['marque'] ?? '';
            $modele = $_POST['modele'] ?? '';
            $couleur = $_POST['couleur'] ?? '';
            $annee = $_POST['annee'] ?? '';
            $username = $_POST['username'] ?? 'system';
            
            // Validation des champs requis
            if (empty(trim($plaque))) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Le numéro de plaque est requis'
                ]);
                break;
            }
            
            // Vérifier l'unicité de la plaque
            if ($vehiculeController->plaqueExists($plaque)) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Cette plaque d\'immatriculation existe déjà dans la base de données'
                ]);
                break;
            }
            
            // Créer le véhicule avec les champs minimum
            $result = $vehiculeController->quickCreate([
                'plaque' => $plaque,
                'marque' => $marque,
                'modele' => $modele,
                'couleur' => $couleur,
                'annee' => $annee,
                'username' => $username
            ]);
            
            if ($result['success']) {
                echo json_encode([
                    'success' => true,
                    'ok' => true,
                    'id' => (int)$result['id'],
                    'vehicule_id' => (int)$result['id'],
                    'message' => 'Véhicule créé avec succès'
                ]);
            } else {
                // Retourner 200 avec success=false pour les erreurs logiques
                echo json_encode([
                    'success' => false,
                    'ok' => false,
                    'error' => $result['message'] ?? 'Erreur lors de la création',
                    'message' => $result['message'] ?? 'Erreur lors de la création'
                ]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'error' => 'Erreur lors de la création du véhicule: ' . $e->getMessage(),
                'message' => 'Erreur lors de la création du véhicule: ' . $e->getMessage()
            ]);
        }
        break;

    // Particulier - Vérifier l'unicité du nom
    case $method === 'GET' && $path === '/check-particulier-exists':
        try {
            $nom = $_GET['nom'] ?? '';
            if (empty($nom)) {
                echo json_encode(['exists' => false]);
                break;
            }
            
            $particulierController = new ParticulierController();
            $exists = $particulierController->nomExists($nom);
            
            echo json_encode(['exists' => $exists]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Erreur lors de la vérification: ' . $e->getMessage()]);
        }
        break;
    case $method === 'POST' && $path === '/create-particulier':
        try {
            $isMultipart = isset($_SERVER['CONTENT_TYPE']) && stripos($_SERVER['CONTENT_TYPE'], 'multipart/form-data') !== false;
            $data = [];
            
            if ($isMultipart) {
                $data = $_POST;
            } else {
                $input = file_get_contents('php://input');
                $data = json_decode($input, true) ?: [];
            }
            
            $pdo = getDbConnection();
            
            // Insérer le particulier
            $stmt = $pdo->prepare("
                INSERT INTO particuliers (
                    nom, adresse, profession, date_naissance, genre, numero_national,
                    gsm, email, lieu_naissance, nationalite, etat_civil,
                    personne_contact, personne_contact_telephone, observations,
                    permis_date_emission, permis_date_expiration
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            
            $dateNaissance = !empty($data['date_naissance']) ? date('Y-m-d H:i:s', strtotime($data['date_naissance'])) : null;
            $permisEmission = !empty($data['permis_date_emission']) ? $data['permis_date_emission'] : null;
            $permisExpiration = !empty($data['permis_date_expiration']) ? $data['permis_date_expiration'] : null;
            
            $stmt->execute([
                $data['nom'] ?? '',
                $data['adresse'] ?? '',
                $data['profession'] ?? '',
                $dateNaissance,
                $data['genre'] ?? '',
                $data['numero_national'] ?? '',
                $data['gsm'] ?? '',
                $data['email'] ?? '',
                $data['lieu_naissance'] ?? '',
                $data['nationalite'] ?? '',
                $data['etat_civil'] ?? '',
                $data['personne_contact'] ?? '',
                $data['personne_contact_telephone'] ?? '',
                $data['observations'] ?? '',
                $permisEmission,
                $permisExpiration
            ]);
            
            $particulierId = $pdo->lastInsertId();
            
            // Gérer les uploads de photos si présents
            $uploadDir = __DIR__ . '/../uploads/particuliers/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0755, true);
            }
            
            $photoFields = ['photo', 'permis_recto', 'permis_verso'];
            $uploadedFiles = [];
            
            foreach ($photoFields as $field) {
                if (isset($_FILES[$field]) && $_FILES[$field]['error'] === UPLOAD_ERR_OK) {
                    $fileName = $particulierId . '_' . $field . '_' . time() . '.' . pathinfo($_FILES[$field]['name'], PATHINFO_EXTENSION);
                    $filePath = $uploadDir . $fileName;
                    
                    if (move_uploaded_file($_FILES[$field]['tmp_name'], $filePath)) {
                        $uploadedFiles[$field] = '/api/uploads/particuliers/' . $fileName;
                        
                        // Mettre à jour la base de données avec le chemin du fichier
                        $updateStmt = $pdo->prepare("UPDATE particuliers SET $field = ? WHERE id = ?");
                        $updateStmt->execute([$uploadedFiles[$field], $particulierId]);
                    }
                }
            }
            
            echo json_encode([
                'status' => 'success',
                'message' => 'Particulier créé avec succès',
                'particulier_id' => $particulierId,
                'uploaded_files' => $uploadedFiles
            ]);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Erreur lors de la création: ' . $e->getMessage()]);
        }
        break;
    case $method === 'POST' && $path === '/create-particulier-with-contravention':
        try {
            $isMultipart = isset($_SERVER['CONTENT_TYPE']) && stripos($_SERVER['CONTENT_TYPE'], 'multipart/form-data') !== false;
            $data = [];
            
            if ($isMultipart) {
                $data = $_POST;
            } else {
                $input = file_get_contents('php://input');
                $data = json_decode($input, true) ?: [];
            }
            
            $pdo = getDbConnection();
            $pdo->beginTransaction();
            
            try {
                // Insérer le particulier
                $stmt = $pdo->prepare("
                    INSERT INTO particuliers (
                        nom, adresse, profession, date_naissance, genre, numero_national,
                        gsm, email, lieu_naissance, nationalite, etat_civil,
                        personne_contact, personne_contact_telephone, observations,
                        permis_date_emission, permis_date_expiration
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ");
                
                $dateNaissance = !empty($data['date_naissance']) ? date('Y-m-d H:i:s', strtotime($data['date_naissance'])) : null;
                $permisEmission = !empty($data['permis_date_emission']) ? $data['permis_date_emission'] : null;
                $permisExpiration = !empty($data['permis_date_expiration']) ? $data['permis_date_expiration'] : null;
                
                $stmt->execute([
                    $data['nom'] ?? '',
                    $data['adresse'] ?? '',
                    $data['profession'] ?? '',
                    $dateNaissance,
                    $data['genre'] ?? '',
                    $data['numero_national'] ?? '',
                    $data['gsm'] ?? '',
                    $data['email'] ?? '',
                    $data['lieu_naissance'] ?? '',
                    $data['nationalite'] ?? '',
                    $data['etat_civil'] ?? '',
                    $data['personne_contact'] ?? '',
                    $data['personne_contact_telephone'] ?? '',
                    $data['observations'] ?? '',
                    $permisEmission,
                    $permisExpiration
                ]);
                
                $particulierId = $pdo->lastInsertId();
                
                // Insérer la contravention
                $contravStmt = $pdo->prepare("
                    INSERT INTO contraventions (
                        dossier_id, type_dossier, date_infraction, lieu, type_infraction, 
                        reference_loi, amende, description, payed
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ");
                
                $contravDateTime = !empty($data['contrav_date_heure']) ? 
                    date('Y-m-d H:i:s', strtotime($data['contrav_date_heure'])) : 
                    date('Y-m-d H:i:s');
                
                $contravStmt->execute([
                    $particulierId,
                    'particuliers',
                    $contravDateTime,
                    $data['contrav_lieu'] ?? '',
                    $data['contrav_type_infraction'] ?? '',
                    $data['contrav_reference_loi'] ?? '',
                    $data['contrav_montant'] ?? 0,
                    $data['contrav_description'] ?? '',
                    ($data['contrav_payee'] ?? '0') === '1' ? 1 : 0
                ]);
                
                $contraventionId = $pdo->lastInsertId();
                
                // Gérer les uploads de photos
                $uploadDir = __DIR__ . '/../uploads/particuliers/';
                if (!is_dir($uploadDir)) {
                    mkdir($uploadDir, 0755, true);
                }
                
                $contravUploadDir = __DIR__ . '/../uploads/contraventions/';
                if (!is_dir($contravUploadDir)) {
                    mkdir($contravUploadDir, 0755, true);
                }
                
                $photoFields = ['photo', 'permis_recto', 'permis_verso'];
                $uploadedFiles = [];
                
                // Photos du particulier
                foreach ($photoFields as $field) {
                    if (isset($_FILES[$field]) && $_FILES[$field]['error'] === UPLOAD_ERR_OK) {
                        $fileName = $particulierId . '_' . $field . '_' . time() . '.' . pathinfo($_FILES[$field]['name'], PATHINFO_EXTENSION);
                        $filePath = $uploadDir . $fileName;
                        
                        if (move_uploaded_file($_FILES[$field]['tmp_name'], $filePath)) {
                            $uploadedFiles[$field] = '/api/uploads/particuliers/' . $fileName;
                            
                            $updateStmt = $pdo->prepare("UPDATE particuliers SET $field = ? WHERE id = ?");
                            $updateStmt->execute([$uploadedFiles[$field], $particulierId]);
                        }
                    }
                }
                
                // Photos de contravention
                if (isset($_FILES['contrav_photos'])) {
                    $contravPhotos = $_FILES['contrav_photos'];
                    $uploadedContravPhotos = [];
                    
                    if (is_array($contravPhotos['name'])) {
                        for ($i = 0; $i < count($contravPhotos['name']); $i++) {
                            if ($contravPhotos['error'][$i] === UPLOAD_ERR_OK) {
                                $fileName = $contraventionId . '_photo_' . $i . '_' . time() . '.' . pathinfo($contravPhotos['name'][$i], PATHINFO_EXTENSION);
                                $filePath = $contravUploadDir . $fileName;
                                
                                if (move_uploaded_file($contravPhotos['tmp_name'][$i], $filePath)) {
                                    $uploadedContravPhotos[] = '/api/uploads/contraventions/' . $fileName;
                                }
                            }
                        }
                    }
                    
                    if (!empty($uploadedContravPhotos)) {
                        $photosJson = json_encode($uploadedContravPhotos);
                        $updateContravStmt = $pdo->prepare("UPDATE contraventions SET photos = ? WHERE id = ?");
                        $updateContravStmt->execute([$photosJson, $contraventionId]);
                    }
                }
                
                $pdo->commit();
                
                echo json_encode([
                    'status' => 'success',
                    'message' => 'Particulier et contravention créés avec succès',
                    'particulier_id' => $particulierId,
                    'contravention_id' => $contraventionId,
                    'uploaded_files' => $uploadedFiles
                ]);
                
            } catch (Exception $e) {
                $pdo->rollback();
                throw $e;
            }
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Erreur lors de la création: ' . $e->getMessage()]);
        }
        break;
    
    // Récupérer un particulier par ID
    case $method === 'GET' && path_match('/particulier/{id}', $path, $p):
        try {
            $particulierId = $p[0];
            
            if (!is_numeric($particulierId)) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'ID particulier invalide'
                ]);
                break;
            }
            
            $particulierController = new ParticulierController();
            $result = $particulierController->getById($particulierId);
            
            if ($result['success']) {
                // Log de la consultation
                LogController::record(
                    $_GET['username'] ?? 'system',
                    'Consultation particulier',
                    [
                        'particulier_id' => $particulierId,
                        'endpoint' => 'GET /particulier/' . $particulierId
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode([
                    'success' => true,
                    'data' => $result['data']
                ]);
            } else {
                http_response_code(404);
                echo json_encode([
                    'success' => false,
                    'message' => $result['message']
                ]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération du particulier: ' . $e->getMessage()
            ]);
        }
        break;
    
    // Récupérer les véhicules d'un particulier
    case $method === 'GET' && path_match('/particulier/{id}/vehicules', $path, $p):
        try {
            $particulierId = $p[0];
            
            if (!is_numeric($particulierId)) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'ID particulier invalide'
                ]);
                break;
            }
            
            $controller = new ParticulierVehiculeController();
            $result = $controller->getVehiculesByParticulier($particulierId);
            
            if ($result['success']) {
                // Log de la consultation
                LogController::record(
                    $_GET['username'] ?? 'system',
                    'Consultation véhicules particulier',
                    [
                        'particulier_id' => $particulierId,
                        'endpoint' => 'GET /particulier/' . $particulierId . '/vehicules',
                        'nb_vehicules' => count($result['data'] ?? [])
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode([
                    'success' => true,
                    'data' => $result['data']
                ]);
            } else {
                http_response_code(404);
                echo json_encode([
                    'success' => false,
                    'message' => $result['message']
                ]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des véhicules: ' . $e->getMessage()
            ]);
        }
        break;

    // Liste des particuliers avec pagination
    case $method === 'GET' && $path === '/particuliers':
        try {
            $page = max(1, (int)($_GET['page'] ?? 1));
            $limit = max(1, min(100, (int)($_GET['limit'] ?? 20)));
            $search = $_GET['search'] ?? '';
            
            $particulierController = new ParticulierController();
            $result = $particulierController->getAll($page, $limit, $search);
            
            if ($result['success']) {
                // Log de la consultation des particuliers
                LogController::record(
                    $_GET['username'] ?? 'system',
                    'Consultation liste particuliers',
                    [
                        'page' => $page,
                        'limit' => $limit,
                        'search' => $search,
                        'total_results' => $result['pagination']['total'] ?? 0
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode([
                    'success' => true,
                    'data' => $result['data'],
                    'pagination' => $result['pagination']
                ]);
            } else {
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'error' => $result['message']
                ]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'error' => 'Erreur lors de la récupération des particuliers: ' . $e->getMessage()
            ]);
        }
        break;

    // Liste des entreprises avec pagination
    case $method === 'GET' && $path === '/entreprises':
        try {
            $page = max(1, (int)($_GET['page'] ?? 1));
            $limit = max(1, min(100, (int)($_GET['limit'] ?? 20)));
            $search = $_GET['search'] ?? '';
            
            $entrepriseController = new EntrepriseController();
            $result = $entrepriseController->getAll($page, $limit, $search);
            
            if ($result['success']) {
                // Log de la consultation des entreprises
                LogController::record(
                    $_GET['username'] ?? 'system',
                    'Consultation liste entreprises',
                    [
                        'page' => $page,
                        'limit' => $limit,
                        'search' => $search,
                        'total_results' => $result['pagination']['total'] ?? 0
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode([
                    'success' => true,
                    'data' => $result['data'],
                    'pagination' => $result['pagination']
                ]);
            } else {
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'error' => $result['message']
                ]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'error' => 'Erreur lors de la récupération des entreprises: ' . $e->getMessage()
            ]);
        }
        break;

    case $method === 'POST' && path_match('/entreprise/{id}/update', $path, $p):
        try {
            if (!isset($p[0])) {
                throw new Exception('ID entreprise manquant');
            }
            
            $id = (int)$p[0];
            
            // Récupérer les données JSON
            $raw = file_get_contents('php://input');
            $data = json_decode($raw, true) ?? [];
            
            if (empty($data)) {
                throw new Exception('Données manquantes');
            }
            
            $entrepriseController = new EntrepriseController();
            $result = $entrepriseController->update($id, $data);
            
            if ($result['success']) {
                // Log de la modification
                LogController::record(
                    $data['username'] ?? 'system',
                    'Modification entreprise',
                    [
                        'entreprise_id' => $id,
                        'fields_updated' => array_keys($data)
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode($result);
            } else {
                http_response_code(400);
                echo json_encode($result);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la modification: ' . $e->getMessage()
            ]);
        }
        break;
    case $method === 'GET' && path_match('/entreprise/{id}', $path, $p):
        json_ok_logged('GET /entreprise/{id}', ['id' => $p[0] ?? null]);
        break;
    
    // Récupérer le propriétaire entreprise d'un véhicule
    case $method === 'GET' && path_match('/vehicule/{id}/proprietaire-entreprise', $path, $p):
        try {
            $vehiculeId = $p[0];
            
            if (!is_numeric($vehiculeId)) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'ID véhicule invalide'
                ]);
                break;
            }
            
            $controller = new EntrepriseVehiculeController();
            $result = $controller->getEntreprisesByVehicule($vehiculeId);
            
            if ($result['success']) {
                // Prendre la plus récente (première dans la liste)
                $entreprise = !empty($result['data']) ? $result['data'][0] : null;
                
                // Log de la consultation
                LogController::record(
                    $_GET['username'] ?? 'system',
                    'Consultation propriétaire entreprise véhicule',
                    [
                        'vehicule_id' => $vehiculeId,
                        'endpoint' => 'GET /vehicule/' . $vehiculeId . '/proprietaire-entreprise',
                        'has_entreprise' => $entreprise !== null
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode([
                    'success' => true,
                    'data' => $entreprise
                ]);
            } else {
                http_response_code(404);
                echo json_encode([
                    'success' => false,
                    'message' => $result['message']
                ]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération du propriétaire: ' . $e->getMessage()
            ]);
        }
        break;
    
    // Récupérer les véhicules d'une entreprise
    case $method === 'GET' && path_match('/entreprise/{id}/vehicules', $path, $p):
        try {
            $entrepriseId = $p[0];
            
            if (!is_numeric($entrepriseId)) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'ID entreprise invalide'
                ]);
                break;
            }
            
            $controller = new EntrepriseVehiculeController();
            $result = $controller->getVehiculesByEntreprise($entrepriseId);
            
            if ($result['success']) {
                // Log de la consultation
                LogController::record(
                    $_GET['username'] ?? 'system',
                    'Consultation véhicules entreprise',
                    [
                        'entreprise_id' => $entrepriseId,
                        'endpoint' => 'GET /entreprise/' . $entrepriseId . '/vehicules',
                        'nb_vehicules' => count($result['data'] ?? [])
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode([
                    'success' => true,
                    'data' => $result['data']
                ]);
            } else {
                http_response_code(404);
                echo json_encode([
                    'success' => false,
                    'message' => $result['message']
                ]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des véhicules: ' . $e->getMessage()
            ]);
        }
        break;

    // Contravention
    case $method === 'POST' && $path === '/contravention/create':
        try {
            $isMultipart = isset($_SERVER['CONTENT_TYPE']) && stripos($_SERVER['CONTENT_TYPE'], 'multipart/form-data') !== false;
            
            if ($isMultipart) {
                // Handle multipart form data (with files)
                $data = $_POST;
                
                // Handle file uploads for photos
                $uploadedPhotos = [];
                if (isset($_FILES['photos']) && is_array($_FILES['photos']['name'])) {
                    $uploadDir = __DIR__ . '/../uploads/contraventions/';
                    if (!is_dir($uploadDir)) {
                        mkdir($uploadDir, 0755, true);
                    }
                    
                    for ($i = 0; $i < count($_FILES['photos']['name']); $i++) {
                        if ($_FILES['photos']['error'][$i] === UPLOAD_ERR_OK) {
                            $fileName = 'contrav_' . time() . '_' . $i . '.' . pathinfo($_FILES['photos']['name'][$i], PATHINFO_EXTENSION);
                            $filePath = $uploadDir . $fileName;
                            
                            if (move_uploaded_file($_FILES['photos']['tmp_name'][$i], $filePath)) {
                                $uploadedPhotos[] = '/api/uploads/contraventions/' . $fileName;
                            }
                        }
                    }
                }
                
                $data['photos'] = implode(',', $uploadedPhotos);
            } else {
                // Handle JSON data
                $raw = file_get_contents('php://input');
                $data = json_decode($raw, true) ?? [];
                $data['photos'] = $data['photos'] ?? '';
            }
            
            // Validate required fields
            if (empty($data['dossier_id']) || empty($data['type_dossier']) || empty($data['type_infraction'])) {
                http_response_code(400);
                echo json_encode([
                    'status' => 'error',
                    'message' => 'Champs requis manquants: dossier_id, type_dossier, type_infraction'
                ]);
                break;
            }
            
            // Create contravention using controller
            $contraventionController = new ContraventionController();
            $result = $contraventionController->create($data);
            
            if ($result['success']) {
                // Generate PDF if creation was successful
                $pdfResult = $contraventionController->generatePdf($result['id']);
                if ($pdfResult['success']) {
                    $result['pdf_url'] = $pdfResult['pdf_url'];
                }
                
                // Log activity
                LogController::record(
                    $data['username'] ?? null,
                    'Création contravention',
                    [
                        'contravention_id' => $result['id'],
                        'dossier_id' => $data['dossier_id'],
                        'type_dossier' => $data['type_dossier'],
                        'type_infraction' => $data['type_infraction']
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode($result);
            } else {
                http_response_code(400);
                echo json_encode($result);
            }
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 'error',
                'message' => 'Erreur lors de la création de la contravention: ' . $e->getMessage()
            ]);
        }
        break;

    // Accidents
    case $method === 'GET' && $path === '/accidents':
        try {
            $accidentController = new AccidentController();
            $result = $accidentController->getAll();
            
            if ($result['success']) {
                echo json_encode([
                    'success' => true,
                    'data' => $result['data'],
                    'pagination' => $result['pagination']
                ]);
            } else {
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'error' => $result['message']
                ]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'error' => 'Erreur lors de la récupération des accidents: ' . $e->getMessage()
            ]);
        }
        break;

    case $method === 'GET' && path_match('/accidents/{id}', $path, $p):
        try {
            if (!isset($p[0])) {
                throw new Exception('ID accident manquant');
            }
            $id = (int)$p[0];
            $accidentController = new AccidentController();
            $result = $accidentController->getById($id);
            
            if ($result['success']) {
                echo json_encode([
                    'success' => true,
                    'data' => $result['data']
                ]);
            } else {
                http_response_code(404);
                echo json_encode([
                    'success' => false,
                    'error' => $result['message']
                ]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'error' => 'Erreur lors de la récupération de l\'accident: ' . $e->getMessage()
            ]);
        }
        break;

    case $method === 'GET' && path_match('/accidents/{id}/temoins', $path, $p):
        try {
            if (!isset($p[0])) {
                throw new Exception('ID accident manquant');
            }
            $id = (int)$p[0];
            
            $database = new Database();
            $db = $database->getConnection();
            if (!$db) {
                throw new Exception('DB connection failed');
            }
            
            $stmt = $db->prepare("SELECT * FROM temoins WHERE id_accident = :id_accident ORDER BY created_at DESC");
            $stmt->bindValue(':id_accident', $id, PDO::PARAM_INT);
            $stmt->execute();
            $temoins = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo json_encode([
                'success' => true,
                'data' => $temoins
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'error' => 'Erreur lors de la récupération des témoins: ' . $e->getMessage()
            ]);
        }
        break;

    case $method === 'GET' && path_match('/accidents/{id}/parties', $path, $p):
        try {
            if (!isset($p[0])) {
                throw new Exception('ID accident manquant');
            }
            $id = (int)$p[0];
            $accidentController = new AccidentController();
            $result = $accidentController->getPartiesImpliquees($id);
            
            if ($result['success']) {
                echo json_encode([
                    'success' => true,
                    'data' => $result['data']
                ]);
            } else {
                http_response_code(404);
                echo json_encode([
                    'success' => false,
                    'error' => $result['message']
                ]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'error' => 'Erreur lors de la récupération des parties impliquées: ' . $e->getMessage()
            ]);
        }
        break;

    // Enterprise creation (simplified: no logo/document uploads)
    case $method === 'POST' && $path === '/create-entreprise':
        try {
            $isMultipart = isset($_SERVER['CONTENT_TYPE']) && stripos($_SERVER['CONTENT_TYPE'], 'multipart/form-data') !== false;
            $data = [];
            if ($isMultipart) {
                // Use POST fields
                $data = $_POST;
            } else {
                $raw = file_get_contents('php://input');
                $data = json_decode($raw, true) ?? [];
            }

            $raison = trim((string)($data['nom_entreprise'] ?? ''));
            $adresse = trim((string)($data['adresse'] ?? ''));
            if ($raison === '' || $adresse === '') {
                http_response_code(400);
                echo json_encode(['status'=>'error','message'=>'Veuillez renseigner nom_entreprise et adresse']);
                break;
            }

            $ent = new EntrepriseController();
            $payload = [
                'nom' => $raison,
                'rccm' => $data['rccm'] ?? '',
                // id_nat supprimé côté client; laisser vide pour compatibilité
                'id_nat' => $data['id_nat'] ?? '',
                'adresse' => $adresse,
                'telephone' => $data['telephone'] ?? '',
                'email' => $data['email'] ?? '',
                'secteur_activite' => $data['type_activite'] ?? '',
                // representant_legal supprimé côté client; fixer à vide pour compatibilité
                'representant_legal' => '',
                'personne_contact' => $data['personne_contact'] ?? '',
                'fonction_contact' => $data['fonction_contact'] ?? '',
                'telephone_contact' => $data['telephone_contact'] ?? '',
                'notes' => $data['notes'] ?? '',
            ];
            $res = $ent->create($payload);
            if ($res['success']) {
                echo json_encode(['status'=>'success','entreprise_id'=>$res['id']]);
            } else {
                http_response_code(400);
                echo json_encode(['status'=>'error','message'=>$res['message'],'debug_payload'=>$payload]);
            }
        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode(['status'=>'error','message'=>$e->getMessage(),'debug_payload'=>$payload ?? null,'debug_data'=>$data ?? null]);
        }
        break;

    case $method === 'POST' && $path === '/create-entreprise-with-contravention':
        try {
            $isMultipart = isset($_SERVER['CONTENT_TYPE']) && stripos($_SERVER['CONTENT_TYPE'], 'multipart/form-data') !== false;
            $isFormData = isset($_SERVER['CONTENT_TYPE']) && stripos($_SERVER['CONTENT_TYPE'], 'application/x-www-form-urlencoded') !== false;
            $data = [];
            if ($isMultipart || $isFormData) { 
                $data = $_POST; 
            } else {
                $raw = file_get_contents('php://input');
                $data = json_decode($raw, true) ?? [];
            }

            $raison = trim((string)($data['raison_sociale'] ?? $data['nom_entreprise'] ?? ''));
            $adresse = trim((string)($data['adresse'] ?? ''));
            $typeInf = trim((string)($data['contrav_type_infraction'] ?? ''));
            if ($raison === '' || $adresse === '' || $typeInf === '') {
                http_response_code(400);
                echo json_encode(['status'=>'error','message'=>'Champs requis manquants: raison_sociale/nom_entreprise, adresse, contrav_type_infraction']);
                break;
            }

            $database = new Database();
            $db = $database->getConnection();
            if (!$db) { throw new Exception('DB connection failed'); }
            $db->beginTransaction();

            // Prepare upload dirs
            $baseUploadDir = __DIR__ . '/../uploads';
            $entDir = $baseUploadDir . '/entreprises';
            $cvDir = $baseUploadDir . '/contraventions';
            if (!is_dir($entDir)) { @mkdir($entDir, 0777, true); }
            if (!is_dir($cvDir)) { @mkdir($cvDir, 0777, true); }

            $saveOne = function($file, $targetDir, $allowedExts, $maxSizeBytes) {
                if (!$file || !isset($file['error']) || $file['error'] !== UPLOAD_ERR_OK) return null;
                if (!is_uploaded_file($file['tmp_name'])) return null;
                if ($file['size'] > $maxSizeBytes) throw new Exception('Fichier trop volumineux');
                $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
                if (!in_array($ext, $allowedExts)) throw new Exception('Extension de fichier non autorisée');
                $safe = uniqid('f_', true) . ($ext ? ('.' . preg_replace('/[^a-z0-9]/', '', $ext)) : '');
                $dest = rtrim($targetDir, '/') . '/' . $safe;
                if (!move_uploaded_file($file['tmp_name'], $dest)) throw new Exception('Échec enregistrement fichier');
                return '/api/uploads/' . basename($targetDir) . '/' . $safe;
            };

            $saveMulti = function($files, $targetDir, $allowedExts, $maxSizeBytes) use ($saveOne) {
                $paths = [];
                if (!$files || !isset($files['name'])) return $paths;
                $isMulti = is_array($files['name']);
                $count = $isMulti ? count($files['name']) : 1;
                for ($i=0; $i<$count; $i++) {
                    $file = [
                        'name' => $isMulti ? $files['name'][$i] : $files['name'],
                        'type' => $isMulti ? $files['type'][$i] : $files['type'],
                        'tmp_name' => $isMulti ? $files['tmp_name'][$i] : $files['tmp_name'],
                        'error' => $isMulti ? $files['error'][$i] : $files['error'],
                        'size' => $isMulti ? $files['size'][$i] : $files['size'],
                    ];
                    $p = $saveOne($file, $targetDir, $allowedExts, $maxSizeBytes);
                    if ($p) $paths[] = $p;
                }
                return $paths;
            };

            $savedLogo = null; $savedDoc = null; $savedPhotos = [];
            if ($isMultipart) {
                if (isset($_FILES['logo'])) { $savedLogo = $saveOne($_FILES['logo'], $entDir, ['jpg','jpeg','png'], 5*1024*1024); }
                if (isset($_FILES['document'])) { $savedDoc = $saveOne($_FILES['document'], $entDir, ['pdf'], 10*1024*1024); }
                if (isset($_FILES['contrav_photos'])) { $savedPhotos = $saveMulti($_FILES['contrav_photos'], $cvDir, ['jpg','jpeg','png','gif'], 8*1024*1024); }
                if (isset($_FILES['contrav_photos']) && !$savedPhotos) { $savedPhotos = []; }
            }

            // Create entreprise
            $ent = new EntrepriseController();
            $payload = [
                'nom' => $raison,
                'rccm' => $data['rccm'] ?? '',
                'id_nat' => $data['id_nat'] ?? '',
                'adresse' => $adresse,
                'telephone' => $data['telephone'] ?? '',
                'email' => $data['email'] ?? '',
                'secteur_activite' => $data['type_activite'] ?? '',
                'representant_legal' => $data['representant_legal'] ?? '',
                'personne_contact' => $data['personne_contact'] ?? '',
                'fonction_contact' => $data['fonction_contact'] ?? '',
                'telephone_contact' => $data['telephone_contact'] ?? '',
                'notes' => $data['notes'] ?? '',
            ];
            $res = $ent->create($payload);
            if (!$res['success']) { throw new Exception($res['message']); }
            $entrepriseId = $res['id'];

            // Create contravention linked to entreprise
            $stmt = $db->prepare("INSERT INTO contraventions (
                dossier_id, type_dossier, date_infraction, lieu, type_infraction, description, reference_loi, amende, payed, photos, created_at
            ) VALUES (
                :dossier_id, :type_dossier, :date_infraction, :lieu, :type_infraction, :description, :reference_loi, :amende, :payed, :photos, NOW()
            )");
            $stmt->bindValue(':dossier_id', $entrepriseId);
            $stmt->bindValue(':type_dossier', 'entreprises');
            $cvDate = $data['contrav_date_heure'] ?? '';
            if (!$cvDate || trim((string)$cvDate) === '') { $cvDate = date('Y-m-d H:i:s'); }
            $stmt->bindValue(':date_infraction', $cvDate);
            $stmt->bindValue(':lieu', $data['contrav_lieu'] ?? '');
            $stmt->bindValue(':type_infraction', $typeInf);
            $stmt->bindValue(':description', $data['contrav_description'] ?? '');
            $stmt->bindValue(':reference_loi', $data['contrav_reference_loi'] ?? '');
            $stmt->bindValue(':amende', $data['contrav_montant'] ?? null);
            $stmt->bindValue(':payed', (!empty($data['contrav_payee']) && ($data['contrav_payee'] === '1' || $data['contrav_payee'] === 1 || $data['contrav_payee'] === true)) ? 'oui' : 'non');
            $stmt->bindValue(':photos', implode(',', $savedPhotos));
            if (!$stmt->execute()) { throw new Exception('Insertion contravention échouée'); }
            $contraventionId = $db->lastInsertId();

            // Commit the transaction first to ensure data is available
            $db->commit();

            // Generate PDF for the contravention
            $contraventionController = new ContraventionController();
            $pdfResult = $contraventionController->generatePdf($contraventionId);
            
            $pdfInfo = [];
            if ($pdfResult['success']) {
                $pdfInfo = [
                    'pdf_generated' => true,
                    'pdf_url' => $pdfResult['pdf_url'],
                    'pdf_message' => $pdfResult['message']
                ];
            } else {
                $pdfInfo = [
                    'pdf_generated' => false,
                    'pdf_error' => $pdfResult['message']
                ];
            }
            echo json_encode(array_merge([
                'status'=>'success',
                'entreprise_id'=>$entrepriseId,
                'contravention_id'=>$contraventionId,
                'contrav_photos'=>$savedPhotos
            ], $pdfInfo));
        } catch (Exception $e) {
            if (isset($db) && $db && $db->inTransaction()) { $db->rollBack(); }
            http_response_code(400);
            echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
        }
        break;
    case $method === 'GET' && path_match('/contravention/{id}', $path, $p):
        json_ok_logged('GET /contravention/{id}', ['id' => $p[0] ?? null]);
        break;
    
    // Update payment status of a contravention
    case $method === 'POST' && path_match('/contravention/{id}/update-payment', $path, $p):
        try {
            if (!isset($p[0])) {
                throw new Exception('ID contravention manquant');
            }
            
            $contraventionId = (int)$p[0];
            
            // Récupérer les données JSON
            $raw = file_get_contents('php://input');
            $data = json_decode($raw, true) ?? [];
            
            if (!isset($data['payed'])) {
                throw new Exception('Statut de paiement manquant');
            }
            
            $payed = $data['payed']; // 'oui' ou 'non'
            
            // Valider le statut
            if (!in_array($payed, ['oui', 'non'])) {
                throw new Exception('Statut de paiement invalide. Doit être "oui" ou "non"');
            }
            
            $database = new Database();
            $db = $database->getConnection();
            
            // Mettre à jour le statut de paiement
            $query = "UPDATE contraventions SET payed = :payed, updated_at = NOW() WHERE id = :id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':payed', $payed);
            $stmt->bindParam(':id', $contraventionId);
            
            if ($stmt->execute()) {
                // Log de la modification
                LogController::record(
                    $data['username'] ?? 'system',
                    'Modification statut paiement contravention',
                    [
                        'contravention_id' => $contraventionId,
                        'nouveau_statut' => $payed
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode([
                    'success' => true,
                    'message' => 'Statut de paiement mis à jour avec succès'
                ]);
            } else {
                throw new Exception('Erreur lors de la mise à jour du statut');
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour: ' . $e->getMessage()
            ]);
        }
        break;
    
    // Get contraventions for a specific particulier
    case $method === 'GET' && path_match('/contraventions/particulier/{id}', $path, $p):
        try {
            if (!isset($p[0])) {
                throw new Exception('ID particulier manquant');
            }
            
            $particulierId = intval($p[0]);
            $controller = new ContraventionController();
            $result = $controller->getByParticulier($particulierId);
            
            if ($result['success']) {
                // Log de la consultation
                LogController::record(
                    $_GET['username'] ?? 'system',
                    'Consultation contraventions particulier',
                    [
                        'particulier_id' => $particulierId,
                        'total_contraventions' => $result['count'] ?? 0
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode($result);
            } else {
                http_response_code(500);
                echo json_encode($result);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contraventions: ' . $e->getMessage()
            ]);
        }
        break;

    // Get arrestations for a specific particulier
    case $method === 'GET' && path_match('/arrestations/particulier/{id}', $path, $p):
        try {
            if (!isset($p[0])) {
                throw new Exception('ID particulier manquant');
            }
            
            $particulierId = intval($p[0]);
            $controller = new ArrestationController();
            $result = $controller->getByParticulier($particulierId);
            
            if ($result['success']) {
                // Log de la consultation
                LogController::record(
                    $_GET['username'] ?? 'system',
                    'Consultation arrestations particulier',
                    [
                        'particulier_id' => $particulierId,
                        'total_arrestations' => $result['count'] ?? 0
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode($result);
            } else {
                http_response_code(500);
                echo json_encode($result);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des arrestations: ' . $e->getMessage()
            ]);
        }
        break;
    
    // Get avis de recherche for a specific particulier
    case $method === 'GET' && path_match('/avis-recherche/particulier/{id}', $path, $p):
        try {
            if (!isset($p[0])) {
                throw new Exception('ID particulier manquant');
            }
            
            require_once __DIR__ . '/../controllers/AvisRechercheController.php';
            $particulierId = intval($p[0]);
            $controller = new AvisRechercheController();
            $result = $controller->getByParticulier($particulierId);
            
            if ($result['success']) {
                // Log de la consultation
                LogController::record(
                    $_GET['username'] ?? 'system',
                    'Consultation avis de recherche particulier',
                    [
                        'particulier_id' => $particulierId,
                        'total_avis' => count($result['data'] ?? [])
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode($result);
            } else {
                http_response_code(500);
                echo json_encode($result);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des avis de recherche: ' . $e->getMessage()
            ]);
        }
        break;
    
    // Get avis de recherche for a specific vehicule
    case $method === 'GET' && path_match('/avis-recherche/vehicule/{id}', $path, $p):
        try {
            if (!isset($p[0])) {
                throw new Exception('ID véhicule manquant');
            }
            
            require_once __DIR__ . '/../controllers/AvisRechercheController.php';
            $vehiculeId = intval($p[0]);
            $controller = new AvisRechercheController();
            $result = $controller->getByVehicule($vehiculeId);
            
            if ($result['success']) {
                // Log de la consultation
                LogController::record(
                    $_GET['username'] ?? 'system',
                    'Consultation avis de recherche véhicule',
                    [
                        'vehicule_id' => $vehiculeId,
                        'total_avis' => count($result['data'] ?? [])
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode($result);
            } else {
                http_response_code(500);
                echo json_encode($result);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des avis de recherche: ' . $e->getMessage()
            ]);
        }
        break;
    
    // Update avis de recherche status
    case $method === 'POST' && path_match('/avis-recherche/{id}/update-status', $path, $p):
        try {
            if (!isset($p[0])) {
                throw new Exception('ID avis de recherche manquant');
            }
            
            $data = json_decode(file_get_contents('php://input'), true);
            if (!isset($data['statut'])) {
                throw new Exception('Statut manquant');
            }
            
            require_once __DIR__ . '/../controllers/AvisRechercheController.php';
            $avisId = intval($p[0]);
            $controller = new AvisRechercheController();
            $result = $controller->updateStatus($avisId, $data['statut']);
            
            if ($result['success']) {
                // Log de la mise à jour
                LogController::record(
                    $data['username'] ?? 'system',
                    'Mise à jour statut avis de recherche',
                    [
                        'avis_id' => $avisId,
                        'nouveau_statut' => $data['statut']
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );
                
                echo json_encode($result);
            } else {
                http_response_code(500);
                echo json_encode($result);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du statut: ' . $e->getMessage()
            ]);
        }
        break;
    
    // Get contraventions for a specific entreprise
    case $method === 'GET' && path_match('/contraventions/entreprise/{id}', $path, $p):
        try {
            if (!isset($p[0])) {
                throw new Exception('ID entreprise manquant');
            }
            
            $entrepriseId = (int)$p[0];
            
            $database = new Database();
            $db = $database->getConnection();
            
            $query = "SELECT * FROM contraventions WHERE dossier_id = :dossier_id AND type_dossier = 'entreprise' ORDER BY created_at DESC";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':dossier_id', $entrepriseId);
            $stmt->execute();
            
            $contraventions = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Log de la consultation
            LogController::record(
                $_GET['username'] ?? 'system',
                'Consultation contraventions entreprise',
                [
                    'entreprise_id' => $entrepriseId,
                    'total_contraventions' => count($contraventions)
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );
            
            echo json_encode([
                'success' => true,
                'data' => $contraventions,
                'total' => count($contraventions)
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contraventions: ' . $e->getMessage()
            ]);
        }
        break;
    case $method === 'GET' && path_match('/contravention/{id}/pdf', $path, $p):
        try {
            if (!isset($p[0])) { throw new Exception('ID contravention manquant'); }
            $id = (int)$p[0];
            
            $contraventionController = new ContraventionController();
            $result = $contraventionController->generatePdf($id);
            
            if ($result['success']) {
                // Return the PDF file path for download
                $pdfPath = $result['pdf_path'];
                if (file_exists($pdfPath)) {
                    header('Content-Type: application/pdf');
                    header('Content-Disposition: attachment; filename="contravention_' . $id . '.pdf"');
                    header('Content-Length: ' . filesize($pdfPath));
                    readfile($pdfPath);
                    exit;
                } else {
                    throw new Exception('Fichier PDF introuvable');
                }
            } else {
                throw new Exception($result['message']);
            }
        } catch (Exception $e) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        break;

    // Accident - Nouveau système de rapport complet
    case $method === 'POST' && $path === '/create-accident':
        require_once __DIR__ . '/../controllers/AccidentRapportController.php';
        $controller = new AccidentRapportController();
        $controller->createRapport();
        exit;
        
    // Accident - Ancien endpoint (conservé pour compatibilité)
    case $method === 'POST' && $path === '/accident/create':
        json_ok_logged('POST /accident/create');
        break;
    case $method === 'POST' && path_match('/accident/{id}/update', $path, $p):
        json_ok_logged('POST /accident/{id}/update', ['id' => $p[0] ?? null]);
        break;
    case $method === 'GET' && path_match('/accident/{id}', $path, $p):
        json_ok_logged('GET /accident/{id}', ['id' => $p[0] ?? null]);
        break;

    // Avis de recherche (endpoints de test supprimés - voir implémentation complète plus bas)
    case $method === 'POST' && path_match('/avis-recherche/{id}/close', $path, $p):
        json_ok_logged('POST /avis-recherche/{id}/close', ['id' => $p[0] ?? null]);
        break;
    case $method === 'GET' && path_match('/avis-recherche/{id}', $path, $p):
        json_ok_logged('GET /avis-recherche/{id}', ['id' => $p[0] ?? null]);
        break;

    // Permis temporaire (endpoint de test supprimé - voir implémentation complète plus bas)
    case $method === 'GET' && path_match('/permis-temporaire/{id}/pdf', $path, $p):
        json_ok_logged('GET /permis-temporaire/{id}/pdf', ['id' => $p[0] ?? null]);
        break;

    // Arrestation (endpoints de test supprimés - voir implémentation complète plus bas)
    case $method === 'POST' && path_match('/arrestation/{id}/release', $path, $p):
        json_ok_logged('POST /arrestation/{id}/release', ['id' => $p[0] ?? null]);
        break;
    case $method === 'GET' && path_match('/particulier/{id}/arrestations', $path, $p):
        json_ok_logged('GET /particulier/{id}/arrestations', ['id' => $p[0] ?? null, 'data' => []]);
        break;


    // Logs (récupérés de la table activites)
    case $method === 'GET' && $path === '/logs':
        try {
            $logController = new LogController();
            
            // Récupérer les paramètres de requête
            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
            $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
            $username = $_GET['username'] ?? null;
            $action = $_GET['action'] ?? null;
            $search = $_GET['search'] ?? null;
            $dateFrom = $_GET['date_from'] ?? null;
            $dateTo = $_GET['date_to'] ?? null;
            
            $result = $logController->getLogs($limit, $offset, $username, $action, $search, $dateFrom, $dateTo);
            
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
                            'action' => $action,
                            'search' => $search,
                            'date_from' => $dateFrom,
                            'date_to' => $dateTo
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
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 'error',
                'message' => 'Erreur serveur: ' . $e->getMessage()
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

    // Contraventions par véhicule
    case $method === 'GET' && path_match('/contraventions/vehicule/{id}', $path, $params):
        require_once __DIR__ . '/../controllers/ContraventionController.php';
        
        $vehiculeId = $params[0];
        $controller = new ContraventionController();
        $result = $controller->getByVehicule($vehiculeId);
        
        // Log the activity
        LogController::record(
            $_GET['username'] ?? $_SERVER['HTTP_X_USERNAME'] ?? 'system',
            "Consultation contraventions véhicule",
            [
                'vehicule_id' => $vehiculeId,
                'endpoint' => "GET /contraventions/vehicule/$vehiculeId"
            ],
            $_SERVER['REMOTE_ADDR'] ?? null,
            $_SERVER['HTTP_USER_AGENT'] ?? null
        );
        
        if ($result['success']) {
            echo json_encode([
                'success' => true,
                'data' => $result['data']
            ]);
        } else {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $result['message']
            ]);
        }
        break;

    // Assurances par véhicule
    case $method === 'GET' && path_match('/assurances/vehicule/{id}', $path, $params):
        require_once __DIR__ . '/../controllers/AssuranceController.php';
        
        $vehiculeId = $params[0];
        $controller = new AssuranceController();
        $result = $controller->getByVehicleId($vehiculeId);
        
        // Log the activity
        LogController::record(
            $_GET['username'] ?? $_SERVER['HTTP_X_USERNAME'] ?? 'system',
            "Consultation assurances véhicule",
            [
                'vehicule_id' => $vehiculeId,
                'endpoint' => "GET /assurances/vehicule/$vehiculeId"
            ],
            $_SERVER['REMOTE_ADDR'] ?? null,
            $_SERVER['HTTP_USER_AGENT'] ?? null
        );
        
        if ($result['success']) {
            echo json_encode([
                'success' => true,
                'data' => $result['data']
            ]);
        } else {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $result['message']
            ]);
        }
        break;

    // Mise à jour du statut de paiement d'une contravention
    case $method === 'POST' && path_match('/contravention/{id}/update-payment', $path, $params):
        try {
            $contraventionId = $params[0] ?? null;
            if (!$contraventionId || !is_numeric($contraventionId)) {
                throw new Exception('ID contravention invalide');
            }

            $raw = file_get_contents('php://input');
            $data = json_decode($raw, true) ?? [];
            
            $payed = $data['payed'] ?? null;
            if (!in_array($payed, ['oui', 'non'])) {
                throw new Exception('Statut de paiement invalide. Valeurs acceptées: "oui" ou "non"');
            }

            $database = new Database();
            $db = $database->getConnection();
            if (!$db) {
                throw new Exception('Erreur de connexion à la base de données');
            }

            // Vérifier que la contravention existe
            $checkStmt = $db->prepare("SELECT id FROM contraventions WHERE id = :id");
            $checkStmt->bindValue(':id', $contraventionId, PDO::PARAM_INT);
            $checkStmt->execute();
            
            if ($checkStmt->rowCount() === 0) {
                throw new Exception('Contravention non trouvée');
            }

            // Mettre à jour le statut de paiement
            $updateStmt = $db->prepare("UPDATE contraventions SET payed = :payed, updated_at = NOW() WHERE id = :id");
            $updateStmt->bindValue(':payed', $payed);
            $updateStmt->bindValue(':id', $contraventionId, PDO::PARAM_INT);
            
            if (!$updateStmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }

            // Log de l'activité
            LogController::record(
                $data['username'] ?? null,
                'Mise à jour statut paiement contravention',
                [
                    'contravention_id' => $contraventionId,
                    'nouveau_statut' => $payed,
                    'action' => 'update_payment_status'
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );

            echo json_encode([
                'success' => true,
                'message' => 'Statut de paiement mis à jour avec succès'
            ]);

        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;

    // Création d'une nouvelle assurance (ajout ou renouvellement)
    case $method === 'POST' && $path === '/assurance/create':
        try {
            require_once __DIR__ . '/../controllers/AssuranceController.php';
            
            $raw = file_get_contents('php://input');
            $data = json_decode($raw, true) ?? [];
            
            // Validation des champs requis
            $required_fields = ['vehicule_plaque_id', 'societe_assurance', 'nume_assurance', 'date_valide_assurance', 'date_expire_assurance'];
            foreach ($required_fields as $field) {
                if (!isset($data[$field]) || empty($data[$field])) {
                    throw new Exception("Le champ '$field' est requis");
                }
            }

            $assuranceController = new AssuranceController();
            $result = $assuranceController->create($data);
            
            if ($result['success']) {
                // Log de l'activité
                LogController::record(
                    $data['username'] ?? null,
                    'Création assurance véhicule',
                    [
                        'vehicule_id' => $data['vehicule_plaque_id'],
                        'assurance_id' => $result['id'],
                        'societe' => $data['societe_assurance'],
                        'numero_police' => $data['nume_assurance'],
                        'date_debut' => $data['date_valide_assurance'],
                        'date_fin' => $data['date_expire_assurance'],
                    ],
                    $_SERVER['REMOTE_ADDR'] ?? null,
                    $_SERVER['HTTP_USER_AGENT'] ?? null
                );

                echo json_encode([
                    'success' => true,
                    'message' => $result['message'],
                    'id' => $result['id']
                ]);
            } else {
                throw new Exception($result['message']);
            }

        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;

    // Création conducteur et véhicule
    case $method === 'POST' && $path === '/conducteur-vehicule/create':
        try {
            require_once __DIR__ . '/../controllers/ConducteurVehiculeController.php';
            
            $conducteurController = new ConducteurVehiculeController();
            $result = $conducteurController->createWithDetails($_POST, $_FILES);
            
            if ($result['success']) {
                echo json_encode($result);
            } else {
                http_response_code(400);
                echo json_encode($result);
            }
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;

    // Liste des conducteurs
    case $method === 'GET' && $path === '/conducteurs':
        try {
            require_once __DIR__ . '/../controllers/ConducteurVehiculeController.php';
            
            $page = (int)($_GET['page'] ?? 1);
            $limit = (int)($_GET['limit'] ?? 20);
            $offset = ($page - 1) * $limit;
            
            $conducteurController = new ConducteurVehiculeController();
            $result = $conducteurController->getAll($limit, $offset);
            
            if ($result['success']) {
                echo json_encode($result);
            } else {
                http_response_code(500);
                echo json_encode($result);
            }
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;

    // Recherche globale
    case $method === 'GET' && $path === '/search/global':
        try {
            require_once __DIR__ . '/../controllers/GlobalSearchController.php';
            
            $query = $_GET['q'] ?? '';
            $limit = (int)($_GET['limit'] ?? 50);
            $username = $_GET['username'] ?? 'system';
            
            $controller = new GlobalSearchController();
            $result = $controller->globalSearch($query, $limit);
            
            // Logging de la recherche
            LogController::record(
                $username,
                'Recherche globale',
                json_encode([
                    'query' => $query,
                    'results_count' => $result['success'] ? $result['total'] : 0,
                    'action' => 'global_search'
                ]),
                $_SERVER['REMOTE_ADDR'] ?? '',
                $_SERVER['HTTP_USER_AGENT'] ?? ''
            );
            
            echo json_encode($result);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;

    // Détails d'un élément trouvé par la recherche globale
    case $method === 'GET' && path_match('/search/details/{type}/{id}', $path, $params):
        try {
            require_once __DIR__ . '/../controllers/GlobalSearchController.php';
            
            $type = $params[0];
            $id = (int)$params[1];
            $username = $_GET['username'] ?? 'system';
            
            $controller = new GlobalSearchController();
            $result = $controller->getDetails($type, $id);
            
            // Logging de la consultation
            LogController::record(
                $username,
                'Consultation détails recherche',
                json_encode([
                    'type' => $type,
                    'id' => $id,
                    'action' => 'view_search_details'
                ]),
                $_SERVER['REMOTE_ADDR'] ?? '',
                $_SERVER['HTTP_USER_AGENT'] ?? ''
            );
            
            echo json_encode($result);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;

    // Création d'arrestation
    case $method === 'POST' && $path === '/arrestation/create':
        try {
            require_once __DIR__ . '/../controllers/ArrestationController.php';
            require_once __DIR__ . '/../controllers/LogController.php';
            
            $data = json_decode(file_get_contents('php://input'), true);
            $username = $data['username'] ?? 'system';
            
            $controller = new ArrestationController();
            $result = $controller->create($data);
            
            // Logging de la création
            if ($result['success']) {
                LogController::record(
                    $username,
                    'Création arrestation',
                    json_encode([
                        'particulier_id' => $data['particulier_id'],
                        'arrestation_id' => $result['id'],
                        'motif' => $data['motif'],
                        'lieu' => $data['lieu'],
                        'date_arrestation' => $data['date_arrestation'],
                        'est_libere' => !empty($data['date_sortie_prison']),
                        'action' => 'create_arrestation'
                    ]),
                    $_SERVER['REMOTE_ADDR'] ?? '',
                    $_SERVER['HTTP_USER_AGENT'] ?? ''
                );
            }
            
            echo json_encode($result);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;

    // Mise à jour du statut de libération
    case $method === 'POST' && path_match('/arrestation/{id}/update-status', $path, $params):
        try {
            require_once __DIR__ . '/../controllers/ArrestationController.php';
            require_once __DIR__ . '/../controllers/LogController.php';
            
            $arrestationId = (int)$params[0];
            $data = json_decode(file_get_contents('php://input'), true);
            $username = $data['username'] ?? 'system';
            
            $dateSortie = $data['est_libere'] ? ($data['date_sortie'] ?? date('Y-m-d H:i:s')) : null;
            
            $controller = new ArrestationController();
            $result = $controller->updateLiberationStatus($arrestationId, $dateSortie);
            
            // Logging de la mise à jour
            if ($result['success']) {
                LogController::record(
                    $username,
                    'Mise à jour statut arrestation',
                    json_encode([
                        'arrestation_id' => $arrestationId,
                        'nouveau_statut' => $data['est_libere'] ? 'libere' : 'en_detention',
                        'date_sortie' => $dateSortie,
                        'action' => 'update_arrestation_status'
                    ]),
                    $_SERVER['REMOTE_ADDR'] ?? '',
                    $_SERVER['HTTP_USER_AGENT'] ?? ''
                );
            }
            
            echo json_encode($result);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;

    // Création d'avis de recherche
    case $method === 'POST' && $path === '/avis-recherche/create':
        try {
            require_once __DIR__ . '/../controllers/AvisRechercheController.php';
            require_once __DIR__ . '/../controllers/LogController.php';
            
            $data = json_decode(file_get_contents('php://input'), true);
            $username = $data['username'] ?? 'system';
            
            $controller = new AvisRechercheController();
            $result = $controller->create($data);
            
            // Logging de la création
            if ($result['success']) {
                LogController::record(
                    $username,
                    'Émission avis de recherche',
                    json_encode([
                        'cible_type' => $data['cible_type'],
                        'cible_id' => $data['cible_id'],
                        'motif' => $data['motif'],
                        'niveau' => $data['niveau'] ?? 'moyen',
                        'avis_id' => $result['id'],
                        'action' => 'create_avis_recherche'
                    ]),
                    $_SERVER['REMOTE_ADDR'] ?? '',
                    $_SERVER['HTTP_USER_AGENT'] ?? ''
                );
            }
            
            echo json_encode($result);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;

    // Création de permis temporaire
    case $method === 'POST' && $path === '/permis-temporaire/create':
        try {
            require_once __DIR__ . '/../controllers/PermisTemporaireController.php';
            require_once __DIR__ . '/../controllers/LogController.php';
            
            $data = json_decode(file_get_contents('php://input'), true);
            $username = $data['username'] ?? 'system';
            
            $controller = new PermisTemporaireController();
            $result = $controller->create($data);
            
            // Logging de la création
            if ($result['success']) {
                LogController::record(
                    $username,
                    'Création permis temporaire',
                    json_encode([
                        'cible_type' => $data['cible_type'],
                        'cible_id' => $data['cible_id'],
                        'numero' => $result['numero'],
                        'motif' => $data['motif'],
                        'date_debut' => $data['date_debut'],
                        'date_fin' => $data['date_fin'],
                        'permis_id' => $result['id'],
                        'action' => 'create_permis_temporaire'
                    ]),
                    $_SERVER['REMOTE_ADDR'] ?? '',
                    $_SERVER['HTTP_USER_AGENT'] ?? ''
                );
            }
            
            echo json_encode($result);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;

    // Sauvegarde PDF permis temporaire
    case $method === 'POST' && path_match('/permis-temporaire/{id}/save-pdf', $path, $p):
        try {
            require_once __DIR__ . '/../controllers/PermisTemporaireController.php';
            
            $permisId = (int)($p[0] ?? 0);
            
            if ($permisId <= 0) {
                http_response_code(400);
                echo json_encode(['ok' => false, 'error' => 'ID permis invalide']);
                break;
            }
            
            // Debug des données reçues
            error_log("DEBUG: _FILES = " . print_r($_FILES, true));
            error_log("DEBUG: _POST = " . print_r($_POST, true));
            
            // Récupérer le fichier PDF uploadé
            if (!isset($_FILES['pdf'])) {
                http_response_code(400);
                echo json_encode(['ok' => false, 'error' => 'Aucun fichier PDF reçu', 'debug' => $_FILES]);
                break;
            }
            
            if ($_FILES['pdf']['error'] !== UPLOAD_ERR_OK) {
                $errorMessages = [
                    UPLOAD_ERR_INI_SIZE => 'Le fichier dépasse la taille maximale autorisée par PHP',
                    UPLOAD_ERR_FORM_SIZE => 'Le fichier dépasse la taille maximale du formulaire',
                    UPLOAD_ERR_PARTIAL => 'Le fichier n\'a été que partiellement téléchargé',
                    UPLOAD_ERR_NO_FILE => 'Aucun fichier n\'a été téléchargé',
                    UPLOAD_ERR_NO_TMP_DIR => 'Dossier temporaire manquant',
                    UPLOAD_ERR_CANT_WRITE => 'Échec de l\'écriture du fichier sur le disque',
                    UPLOAD_ERR_EXTENSION => 'Une extension PHP a arrêté le téléchargement'
                ];
                
                $errorCode = $_FILES['pdf']['error'];
                $errorMessage = $errorMessages[$errorCode] ?? "Erreur inconnue ($errorCode)";
                
                http_response_code(400);
                echo json_encode([
                    'ok' => false, 
                    'error' => 'Erreur d\'upload: ' . $errorMessage,
                    'error_code' => $errorCode,
                    'file_info' => $_FILES['pdf']
                ]);
                break;
            }
            
            $pdfContent = file_get_contents($_FILES['pdf']['tmp_name']);
            
            $controller = new PermisTemporaireController();
            $result = $controller->savePdf($permisId, $pdfContent);
            
            if ($result['success']) {
                echo json_encode(['ok' => true, 'message' => $result['message'], 'pdf_path' => $result['pdf_path']]);
            } else {
                http_response_code(500);
                echo json_encode(['ok' => false, 'error' => $result['message']]);
            }
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['ok' => false, 'error' => $e->getMessage()]);
        }
        break;

    // Récupération des permis temporaires d'un particulier
    case $method === 'GET' && path_match('/permis-temporaires/particulier/{id}', $path, $p):
        try {
            require_once __DIR__ . '/../controllers/PermisTemporaireController.php';
            require_once __DIR__ . '/../controllers/LogController.php';
            
            $particulierId = (int)($p[0] ?? 0);
            $username = $_GET['username'] ?? 'system';
            
            if ($particulierId <= 0) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'ID particulier invalide']);
                break;
            }
            
            $controller = new PermisTemporaireController();
            $result = $controller->getByParticulier($particulierId);
            
            // Logging de la consultation
            LogController::record(
                $username,
                'Consultation permis temporaires particulier',
                json_encode([
                    'particulier_id' => $particulierId,
                    'count' => count($result['data'] ?? []),
                    'endpoint' => "GET /permis-temporaires/particulier/{$particulierId}"
                ]),
                $_SERVER['REMOTE_ADDR'] ?? '',
                $_SERVER['HTTP_USER_AGENT'] ?? ''
            );
            
            echo json_encode($result);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;

    // Création d'une plaque temporaire
    case $method === 'POST' && path_match('/plaque-temporaire/create', $path, $p):
        try {
            require_once __DIR__ . '/../controllers/PermisTemporaireController.php';
            require_once __DIR__ . '/../controllers/LogController.php';
            
            $data = json_decode(file_get_contents('php://input'), true);
            
            if (!$data) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'Données JSON invalides']);
                break;
            }
            
            // Validation des champs requis
            $requiredFields = ['cible_type', 'cible_id', 'date_debut', 'date_fin'];
            foreach ($requiredFields as $field) {
                if (!isset($data[$field]) || empty($data[$field])) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'message' => "Le champ '$field' est requis"]);
                    break 2;
                }
            }
            
            // Générer un numéro de plaque temporaire au format PT-XXXXXX
            $data['numero'] = generatePlaqueTemporaireNumber();
            $data['created_by'] = $_SESSION['user_id'] ?? 1; // ID de l'utilisateur connecté
            
            $controller = new PermisTemporaireController();
            $result = $controller->create($data);
            
            if ($result['success']) {
                // Logging de la création
                LogController::record(
                    $_SESSION['username'] ?? 'system',
                    'Création plaque temporaire',
                    json_encode([
                        'plaque_id' => $result['id'],
                        'numero' => $result['numero'],
                        'vehicule_id' => $data['cible_id'],
                        'date_debut' => $data['date_debut'],
                        'date_fin' => $data['date_fin'],
                        'action' => 'create_plaque_temporaire'
                    ]),
                    $_SERVER['REMOTE_ADDR'] ?? '',
                    $_SERVER['HTTP_USER_AGENT'] ?? ''
                );
                
                echo json_encode($result);
            } else {
                http_response_code(500);
                echo json_encode($result);
            }
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur serveur: ' . $e->getMessage()]);
        }
        break;

    // Sauvegarde PDF plaque temporaire
    case $method === 'POST' && path_match('/plaque-temporaire/{id}/save-pdf', $path, $p):
        try {
            require_once __DIR__ . '/../controllers/PermisTemporaireController.php';
            
            $plaqueId = (int)($p[0] ?? 0);
            
            if ($plaqueId <= 0) {
                http_response_code(400);
                echo json_encode(['ok' => false, 'error' => 'ID plaque invalide']);
                break;
            }
            
            // Récupérer le fichier PDF uploadé
            if (!isset($_FILES['pdf']) || $_FILES['pdf']['error'] !== UPLOAD_ERR_OK) {
                http_response_code(400);
                echo json_encode(['ok' => false, 'error' => 'Fichier PDF manquant ou invalide']);
                break;
            }
            
            $pdfContent = file_get_contents($_FILES['pdf']['tmp_name']);
            
            $controller = new PermisTemporaireController();
            $result = $controller->savePdf($plaqueId, $pdfContent);
            
            if ($result['success']) {
                echo json_encode(['ok' => true, 'message' => $result['message'], 'pdf_path' => $result['pdf_path']]);
            } else {
                http_response_code(500);
                echo json_encode(['ok' => false, 'error' => $result['message']]);
            }
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['ok' => false, 'error' => $e->getMessage()]);
        }
        break;

    // Récupération des plaques temporaires d'un véhicule
    case $method === 'GET' && path_match('/plaques-temporaires/vehicule/{id}', $path, $p):
        try {
            require_once __DIR__ . '/../controllers/PermisTemporaireController.php';
            require_once __DIR__ . '/../controllers/LogController.php';
            
            $vehiculeId = (int)($p[0] ?? 0);
            $username = $_GET['username'] ?? 'system';
            
            if ($vehiculeId <= 0) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'ID véhicule invalide']);
                break;
            }
            
            // Récupérer les plaques temporaires pour ce véhicule
            $pdo = getDbConnection();
            $stmt = $pdo->prepare("
                SELECT * FROM permis_temporaire 
                WHERE cible_type = 'vehicule_plaque' AND cible_id = :vehicule_id 
                ORDER BY created_at DESC
            ");
            $stmt->bindParam(':vehicule_id', $vehiculeId, PDO::PARAM_INT);
            $stmt->execute();
            
            $plaquesTemporaires = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Logging de la consultation
            LogController::record(
                $username,
                'Consultation plaques temporaires véhicule',
                json_encode([
                    'vehicule_id' => $vehiculeId,
                    'count' => count($plaquesTemporaires),
                    'endpoint' => "GET /plaques-temporaires/vehicule/$vehiculeId"
                ]),
                $_SERVER['REMOTE_ADDR'] ?? '',
                $_SERVER['HTTP_USER_AGENT'] ?? ''
            );
            
            echo json_encode([
                'success' => true,
                'data' => $plaquesTemporaires,
                'count' => count($plaquesTemporaires)
            ]);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
        break;

    // Modification d'un particulier
    case $method === 'POST' && path_match('/particulier/{id}/update', $path, $p):
        try {
            require_once __DIR__ . '/../controllers/ParticulierController.php';
            require_once __DIR__ . '/../controllers/LogController.php';
            
            $particulierId = (int)($p[0] ?? 0);
            
            if ($particulierId <= 0) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'ID particulier invalide']);
                break;
            }
            
            // Récupérer les données POST et FILES
            $data = $_POST;
            $files = $_FILES;
            $username = $data['username'] ?? 'system';
            
            // Validation des champs requis
            if (empty($data['nom']) || empty($data['gsm']) || empty($data['adresse'])) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Les champs nom, téléphone et adresse sont requis'
                ]);
                break;
            }
            
            $controller = new ParticulierController();
            $result = $controller->updateComplete($particulierId, $data, $files);
            
            if ($result['success']) {
                // Logging de la modification
                LogController::record(
                    $username,
                    'Modification particulier',
                    json_encode([
                        'particulier_id' => $particulierId,
                        'champs_modifies' => array_keys($data),
                        'photos_uploadees' => $result['photos_uploaded'] ?? [],
                        'action' => 'update_particulier'
                    ]),
                    $_SERVER['REMOTE_ADDR'] ?? '',
                    $_SERVER['HTTP_USER_AGENT'] ?? ''
                );
                
                echo json_encode($result);
            } else {
                http_response_code(400);
                echo json_encode($result);
            }
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur serveur: ' . $e->getMessage()
            ]);
        }
        break;

    // Récupération de toutes les alertes
    case $method === 'GET' && $path === '/alerts':
        try {
            require_once __DIR__ . '/../controllers/AvisRechercheController.php';
            require_once __DIR__ . '/../controllers/AssuranceController.php';
            
            $pdo = getDbConnection();
            $username = $_GET['username'] ?? 'system';
            
            $alerts = [
                'avis_recherche_actifs' => [],
                'assurances_expirees' => [],
                'permis_temporaires_expires' => [],
                'plaques_expirees' => [],
                'permis_conduire_expires' => []
            ];
            
            // 1. Avis de recherche actifs
            $avisController = new AvisRechercheController();
            $avisResult = $avisController->getActive();
            if ($avisResult['success']) {
                // Enrichir avec les détails de la cible
                foreach ($avisResult['data'] as &$avis) {
                    if ($avis['cible_type'] === 'vehicule_plaque') {
                        $stmt = $pdo->prepare("SELECT id, plaque, marque, modele FROM vehicule_plaque WHERE id = :id");
                        $stmt->bindParam(':id', $avis['cible_id']);
                        $stmt->execute();
                        $avis['cible_details'] = $stmt->fetch(PDO::FETCH_ASSOC);
                    } elseif ($avis['cible_type'] === 'particulier' || $avis['cible_type'] === 'particuliers') {
                        $stmt = $pdo->prepare("SELECT id, nom, gsm FROM particuliers WHERE id = :id");
                        $stmt->bindParam(':id', $avis['cible_id']);
                        $stmt->execute();
                        $avis['cible_details'] = $stmt->fetch(PDO::FETCH_ASSOC);
                    }
                }
                $alerts['avis_recherche_actifs'] = $avisResult['data'];
            }
            
            // 2. Assurances expirées
            $assuranceController = new AssuranceController();
            $assuranceResult = $assuranceController->getExpiredAssurances();
            if ($assuranceResult['success']) {
                $alerts['assurances_expirees'] = $assuranceResult['data'];
            }
            
            // 3. Permis temporaires expirés
            $stmt = $pdo->prepare("
                SELECT pt.*, 
                    CASE 
                        WHEN pt.cible_type = 'vehicule_plaque' THEN v.plaque
                        WHEN pt.cible_type IN ('particulier', 'particuliers') THEN p.nom
                        ELSE NULL
                    END as cible_nom
                FROM permis_temporaire pt
                LEFT JOIN vehicule_plaque v ON pt.cible_type = 'vehicule_plaque' AND pt.cible_id = v.id
                LEFT JOIN particuliers p ON pt.cible_type IN ('particulier', 'particuliers') AND pt.cible_id = p.id
                WHERE pt.date_fin < NOW() AND pt.statut = 'actif'
                ORDER BY pt.date_fin DESC
            ");
            $stmt->execute();
            $alerts['permis_temporaires_expires'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // 4. Plaques expirées
            $stmt = $pdo->prepare("
                SELECT id, plaque, marque, modele, plaque_expire_le, couleur, annee
                FROM vehicule_plaque 
                WHERE plaque_expire_le < NOW() AND en_circulation = 1
                ORDER BY plaque_expire_le DESC
            ");
            $stmt->execute();
            $alerts['plaques_expirees'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // 5. Permis de conduire expirés
            $stmt = $pdo->prepare("
                SELECT id, nom, gsm, permis_date_expiration, adresse
                FROM particuliers 
                WHERE permis_date_expiration < NOW()
                ORDER BY permis_date_expiration DESC
            ");
            $stmt->execute();
            $alerts['permis_conduire_expires'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Compter les alertes
            $total = count($alerts['avis_recherche_actifs']) +
                     count($alerts['assurances_expirees']) +
                     count($alerts['permis_temporaires_expires']) +
                     count($alerts['plaques_expirees']) +
                     count($alerts['permis_conduire_expires']);
            
            // Logging de la consultation
            LogController::record(
                $username,
                'Consultation alertes',
                json_encode([
                    'total_alerts' => $total,
                    'avis_recherche' => count($alerts['avis_recherche_actifs']),
                    'assurances_expirees' => count($alerts['assurances_expirees']),
                    'permis_temporaires_expires' => count($alerts['permis_temporaires_expires']),
                    'plaques_expirees' => count($alerts['plaques_expirees']),
                    'permis_conduire_expires' => count($alerts['permis_conduire_expires']),
                    'endpoint' => 'GET /alerts'
                ]),
                $_SERVER['REMOTE_ADDR'] ?? '',
                $_SERVER['HTTP_USER_AGENT'] ?? ''
            );
            
            echo json_encode([
                'success' => true,
                'data' => $alerts,
                'total' => $total
            ]);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur serveur: ' . $e->getMessage()
            ]);
        }
        break;

    // Route de test santé API
    case $method === 'GET' && $path === '/health':
        echo json_encode([
            'status' => 'success',
            'message' => 'API BCR fonctionne correctement',
            'timestamp' => date('Y-m-d H:i:s'),
            'version' => '1.0.0',
            'database' => 'connected'
        ]);
        break;

    // Route de test avec informations système
    case $method === 'GET' && $path === '/test':
        echo json_encode([
            'status' => 'success',
            'message' => 'Route de test API BCR',
            'server_time' => date('Y-m-d H:i:s'),
            'php_version' => PHP_VERSION,
            'request_method' => $_SERVER['REQUEST_METHOD'],
            'request_uri' => $_SERVER['REQUEST_URI'],
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown'
        ]);
        break;

    default:
        http_response_code(404);
        echo json_encode(['status' => 'error', 'message' => 'Not Found', 'path' => $path, 'method' => $method]);
        break;
}
?>
