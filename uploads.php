<?php
// Script pour servir les fichiers uploads en développement local
// Usage: /uploads.php/contraventions/image.jpg

$requestUri = $_SERVER['REQUEST_URI'];
$path = parse_url($requestUri, PHP_URL_PATH);

// Extraire le chemin après /uploads.php
if (strpos($path, '/uploads.php/') === 0) {
    $filePath = substr($path, strlen('/uploads.php/'));
} else {
    http_response_code(404);
    exit('File not found');
}

// Chemin complet vers le fichier
$fullPath = __DIR__ . '/api/uploads/' . $filePath;

// Vérifier que le fichier existe et est dans le dossier uploads
if (!file_exists($fullPath) || strpos(realpath($fullPath), realpath(__DIR__ . '/api/uploads/')) !== 0) {
    http_response_code(404);
    exit('File not found');
}

// Déterminer le type MIME
$extension = strtolower(pathinfo($fullPath, PATHINFO_EXTENSION));
$mimeTypes = [
    'jpg' => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'pdf' => 'application/pdf',
    'svg' => 'image/svg+xml',
    'webp' => 'image/webp'
];

$mimeType = $mimeTypes[$extension] ?? 'application/octet-stream';

// Envoyer les en-têtes appropriés
header('Content-Type: ' . $mimeType);
header('Content-Length: ' . filesize($fullPath));
header('Cache-Control: public, max-age=3600'); // Cache 1 heure

// Envoyer le fichier
readfile($fullPath);
?>
