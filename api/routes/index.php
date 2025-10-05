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

function getDbConnection() {
    $database = new Database();
    return $database->getConnection();
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

            $vehiculeController = new VehiculeController();
            $result = $vehiculeController->retirerPlaque((int)$vehiculeId);
            
            if (!$result['success']) {
                throw new Exception($result['message']);
            }

            // Log de l'activité
            LogController::record(
                $_POST['username'] ?? null,
                'Retrait de plaque',
                [
                    'vehicule_id' => $vehiculeId,
                    'ancienne_plaque' => $result['ancienne_plaque'] ?? null,
                    'action' => 'retrait_plaque'
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

    // Particulier
    case $method === 'GET' && $path === '/check-particulier-exists':
        try {
            $nom = $_GET['nom'] ?? '';
            if (empty($nom)) {
                echo json_encode(['exists' => false]);
                break;
            }
            
            $pdo = getDbConnection();
            $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM particuliers WHERE LOWER(nom) = LOWER(?)");
            $stmt->execute([$nom]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            echo json_encode(['exists' => $result['count'] > 0]);
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
                        $uploadedFiles[$field] = 'uploads/particuliers/' . $fileName;
                        
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
                            $uploadedFiles[$field] = 'uploads/particuliers/' . $fileName;
                            
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
                                    $uploadedContravPhotos[] = 'uploads/contraventions/' . $fileName;
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
    case $method === 'POST' && $path === '/particulier/create':
        json_ok_logged('POST /particulier/create');
        break;
    case $method === 'POST' && path_match('/particulier/{id}/update', $path, $p):
        json_ok_logged('POST /particulier/{id}/update', ['id' => $p[0] ?? null]);
        break;
    case $method === 'GET' && path_match('/particulier/{id}', $path, $p):
        json_ok_logged('GET /particulier/{id}', ['id' => $p[0] ?? null]);
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

    // Entreprise
    case $method === 'POST' && $path === '/entreprise/create':
        try {
            $raw = file_get_contents('php://input');
            $data = json_decode($raw, true);
            if (!is_array($data)) { $data = []; }

            $raison = trim((string)($data['raison_sociale'] ?? ''));
            $adresse = trim((string)($data['adresse'] ?? ''));
            if ($raison === '' || $adresse === '') {
                http_response_code(400);
                echo json_encode(['status'=>'error','message'=>'Champs requis manquants: raison_sociale, adresse']);
                break;
            }

            $ent = new EntrepriseController();
            $payload = [
                'nom' => $raison,
                'rccm' => $data['rccm'] ?? '',
                'id_nat' => $data['id_nat'] ?? '',
                'adresse' => $adresse,
                'telephone' => $data['telephone'] ?? '',
                'email' => $data['email'] ?? '',
                'secteur_activite' => $data['type_activite'] ?? '',
                // representant_legal supprimé côté client; fixer à vide pour compatibilité
                'representant_legal' => '',
            ];
            $res = $ent->create($payload);
            if ($res['success']) {
                json_ok_logged('POST /entreprise/create', ['entreprise_id' => $res['id']]);
            } else {
                http_response_code(400);
                echo json_encode(['status'=>'error','message'=>$res['message']]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
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
                                $uploadedPhotos[] = 'uploads/contraventions/' . $fileName;
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

    default:
        http_response_code(404);
        echo json_encode(['status' => 'error', 'message' => 'Not Found', 'path' => $path, 'method' => $method]);
        break;
}
?>
