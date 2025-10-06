<?php
// Script pour vérifier les limites PHP actuelles
header('Content-Type: application/json');

$limits = [
    'upload_max_filesize' => ini_get('upload_max_filesize'),
    'post_max_size' => ini_get('post_max_size'),
    'max_execution_time' => ini_get('max_execution_time'),
    'max_input_time' => ini_get('max_input_time'),
    'memory_limit' => ini_get('memory_limit'),
    'max_file_uploads' => ini_get('max_file_uploads'),
];

// Convertir en bytes pour comparaison
function convertToBytes($value) {
    $value = trim($value);
    $last = strtolower($value[strlen($value)-1]);
    $value = (int) $value;
    
    switch($last) {
        case 'g':
            $value *= 1024;
        case 'm':
            $value *= 1024;
        case 'k':
            $value *= 1024;
    }
    
    return $value;
}

$uploadMaxBytes = convertToBytes($limits['upload_max_filesize']);
$postMaxBytes = convertToBytes($limits['post_max_size']);

$response = [
    'success' => true,
    'limits' => $limits,
    'upload_max_bytes' => $uploadMaxBytes,
    'post_max_bytes' => $postMaxBytes,
    'upload_100mb_ok' => $uploadMaxBytes >= (100 * 1024 * 1024),
    'post_100mb_ok' => $postMaxBytes >= (100 * 1024 * 1024),
    'upload_50mb_ok' => $uploadMaxBytes >= (50 * 1024 * 1024),
    'post_50mb_ok' => $postMaxBytes >= (50 * 1024 * 1024),
    'message' => 'Limites PHP vérifiées - Configuration mise à jour à 100MB'
];

echo json_encode($response, JSON_PRETTY_PRINT);
?>
