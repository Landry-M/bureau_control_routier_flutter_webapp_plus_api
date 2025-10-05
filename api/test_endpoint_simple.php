<?php
/**
 * Test simple de l'endpoint d'authentification
 */

// Activer l'affichage des erreurs
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "=== TEST SIMPLE DE L'ENDPOINT ===\n\n";

// Simuler les variables d'environnement pour le routeur
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['REQUEST_URI'] = '/auth/login';
$_GET['route'] = '/auth/login';

// Données de test
$testData = json_encode([
    'matricule' => 'boom',
    'password' => 'boombeach'
]);

echo "Données de test: $testData\n\n";

// Créer un fichier temporaire pour simuler php://input
$tempFile = tempnam(sys_get_temp_dir(), 'test_input');
file_put_contents($tempFile, $testData);

// Rediriger php://input vers notre fichier temporaire
stream_wrapper_unregister('php');
stream_wrapper_register('php', 'TestInputStream');

class TestInputStream {
    private $position = 0;
    private $data;
    
    public function stream_open($path, $mode, $options, &$opened_path) {
        if ($path === 'php://input') {
            global $testData;
            $this->data = $testData;
            $this->position = 0;
            return true;
        }
        return false;
    }
    
    public function stream_read($count) {
        $ret = substr($this->data, $this->position, $count);
        $this->position += strlen($ret);
        return $ret;
    }
    
    public function stream_eof() {
        return $this->position >= strlen($this->data);
    }
    
    public function stream_stat() {
        return array();
    }
}

try {
    echo "Inclusion du routeur...\n";
    
    // Capturer la sortie
    ob_start();
    
    // Inclure le routeur
    include __DIR__ . '/routes/index.php';
    
    $output = ob_get_clean();
    
    echo "=== SORTIE DU ROUTEUR ===\n";
    echo $output . "\n";
    
    // Analyser la réponse
    $jsonResponse = json_decode($output, true);
    if ($jsonResponse) {
        echo "\n=== ANALYSE JSON ===\n";
        if (isset($jsonResponse['status'])) {
            echo "Status: {$jsonResponse['status']}\n";
            if ($jsonResponse['status'] === 'ok') {
                echo "✅ Connexion réussie!\n";
                echo "Token: " . ($jsonResponse['token'] ?? 'N/A') . "\n";
                echo "Rôle: " . ($jsonResponse['role'] ?? 'N/A') . "\n";
            } else {
                echo "❌ Connexion échouée\n";
                echo "Message: " . ($jsonResponse['message'] ?? 'N/A') . "\n";
            }
        }
    } else {
        echo "❌ Réponse non-JSON: $output\n";
    }
    
} catch (Exception $e) {
    echo "❌ Exception: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
} catch (Error $e) {
    echo "❌ Erreur fatale: " . $e->getMessage() . "\n";
    echo "Fichier: " . $e->getFile() . " ligne " . $e->getLine() . "\n";
}

// Nettoyer
unlink($tempFile);
stream_wrapper_restore('php');
?>
