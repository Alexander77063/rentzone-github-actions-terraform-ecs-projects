#!/bin/bash

# Exit on any error
set -e

echo "[$(date)] Starting services..."

# Create directory for PHP-FPM
if [ ! -d /run/php-fpm ]; then
    echo "[$(date)] Creating PHP-FPM directory..."
    mkdir -p /run/php-fpm
fi

# Start PHP-FPM
echo "[$(date)] Starting PHP-FPM..."
if ! php-fpm -D; then
    echo "[$(date)] ERROR: Failed to start PHP-FPM"
    exit 1
fi

# Verify PHP-FPM is running
if ! pgrep php-fpm > /dev/null; then
    echo "[$(date)] ERROR: PHP-FPM failed to start properly"
    exit 1
fi
echo "[$(date)] PHP-FPM started successfully"

# Start Apache
echo "[$(date)] Starting Apache..."
exec /usr/sbin/httpd -D FOREGROUND