<?php
/**
 * Router script for PHP built-in server with CORS support
 * Usage: php -S localhost:8000 -t api/ api/router.php
 */

// Set CORS headers FIRST, before any other processing
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin, X-Auth-Token, X-API-Key');
header('Access-Control-Max-Age: 86400');

// Handle OPTIONS (preflight) requests immediately
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

// Serve static files directly (uploads, assets, etc.)
if (preg_match('/^\/api\/uploads\//', $uri) || preg_match('/^\/api\/assets\//', $uri)) {
    return false; // Let the built-in server serve the file
}

// Handle contravention_display.php
if ($uri === '/api/contravention_display.php' || preg_match('/^\/api\/contravention_display\.php/', $uri)) {
    require __DIR__ . '/contravention_display.php';
    exit;
}

// Allow direct access to existing files
if ($uri !== '/' && file_exists(__DIR__ . $uri)) {
    return false; // Let the built-in server serve the file
}

// Route all API requests to routes/index.php
if (preg_match('/^\/api\/routes\/index\.php/', $uri) || preg_match('/^\/api\//', $uri)) {
    require __DIR__ . '/routes/index.php';
    exit;
}

// For root or other paths, serve index.php if it exists
if (file_exists(__DIR__ . '/index.php')) {
    require __DIR__ . '/index.php';
} else {
    http_response_code(404);
    echo "404 Not Found";
}
