<?php
/**
 * Script de test pour vérifier l'accès CORS aux fichiers uploads
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: *');

function testUploadAccess() {
    $baseUrl = 'http://localhost/api/uploads/';
    $testResults = [];
    
    // Dossiers à tester
    $folders = ['contraventions', 'particuliers', 'entreprises', 'vehicules', 'conducteurs', 'accidents', 'parties_impliquees', 'permis_temporaire'];
    
    foreach ($folders as $folder) {
        $folderPath = __DIR__ . '/api/uploads/' . $folder;
        $folderUrl = $baseUrl . $folder . '/';
        
        $testResults[$folder] = [
            'folder_exists' => is_dir($folderPath),
            'folder_readable' => is_readable($folderPath),
            'htaccess_exists' => file_exists($folderPath . '/.htaccess'),
            'test_url' => $folderUrl,
            'files' => []
        ];
        
        // Lister les fichiers dans le dossier
        if (is_dir($folderPath)) {
            $files = array_diff(scandir($folderPath), array('.', '..', '.htaccess', '.DS_Store'));
            foreach ($files as $file) {
                $filePath = $folderPath . '/' . $file;
                if (is_file($filePath)) {
                    $testResults[$folder]['files'][] = [
                        'name' => $file,
                        'size' => filesize($filePath),
                        'url' => $folderUrl . $file,
                        'readable' => is_readable($filePath)
                    ];
                }
            }
        }
    }
    
    return $testResults;
}

function testCorsHeaders() {
    $headers = [
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, HEAD, OPTIONS',
        'Access-Control-Allow-Headers' => '*'
    ];
    
    foreach ($headers as $header => $value) {
        header("$header: $value");
    }
    
    return $headers;
}

// Test principal
$results = [
    'timestamp' => date('Y-m-d H:i:s'),
    'message' => 'Test d\'accès CORS aux fichiers uploads',
    'cors_headers' => testCorsHeaders(),
    'upload_folders' => testUploadAccess(),
    'recommendations' => [
        'Vérifiez que mod_headers est activé sur votre serveur Apache',
        'Assurez-vous que les fichiers .htaccess sont bien pris en compte',
        'Testez l\'accès direct aux URLs des fichiers depuis un navigateur',
        'Vérifiez les logs d\'erreur Apache si des problèmes persistent'
    ]
];

echo json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
