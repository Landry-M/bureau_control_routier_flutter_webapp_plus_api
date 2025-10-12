#!/bin/bash
# Script to start PHP API server with CORS support

# Kill any existing server on port 8000
lsof -ti:8000 | xargs kill -9 2>/dev/null || true
echo "Killed existing server on port 8000"

# Wait a moment
sleep 1

# Start the server with the router that handles CORS
cd "$(dirname "$0")"
echo "Starting PHP server on localhost:8000 with CORS support..."
php -S localhost:8000 -t api/ api/router.php
