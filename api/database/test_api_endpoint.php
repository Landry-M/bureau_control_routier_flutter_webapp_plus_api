<?php
/**
 * Test direct de l'endpoint /auth/login pour l'utilisateur boom
 */

// Simuler une requête POST à l'endpoint /auth/login
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['REQUEST_URI'] = '/auth/login';

// Simuler les données JSON envoyées
$testData = [
    'matricule' => 'boom',
    'password' => 'boombeach'
];

// Capturer la sortie
ob_start();

// Simuler l'input JSON
$GLOBALS['test_input'] = json_encode($testData);

// Redéfinir file_get_contents pour notre test
function file_get_contents($filename) {
    if ($filename === 'php://input') {
        return $GLOBALS['test_input'];
    }
    return call_user_func_array('\\file_get_contents', func_get_args());
}

echo "=== TEST DIRECT DE L'ENDPOINT /auth/login ===\n";
echo "Données envoyées: " . json_encode($testData) . "\n\n";

// Inclure le routeur principal
try {
    include __DIR__ . '/../routes/index.php';
} catch (Exception $e) {
    echo "Erreur lors de l'inclusion du routeur: " . $e->getMessage() . "\n";
}

$output = ob_get_clean();

echo "=== RÉPONSE DE L'API ===\n";
echo $output . "\n";

// Vérifier si c'est du JSON valide
$jsonResponse = json_decode($output, true);
if ($jsonResponse) {
    echo "\n=== ANALYSE DE LA RÉPONSE ===\n";
    if (isset($jsonResponse['status']) && $jsonResponse['status'] === 'ok') {
        echo "✅ Connexion réussie via l'endpoint API\n";
        echo "Token: " . ($jsonResponse['token'] ?? 'N/A') . "\n";
        echo "Rôle: " . ($jsonResponse['role'] ?? 'N/A') . "\n";
    } else {
        echo "❌ Connexion échouée\n";
        echo "Message: " . ($jsonResponse['message'] ?? 'N/A') . "\n";
    }
} else {
    echo "❌ Réponse non-JSON ou invalide\n";
}
?>
