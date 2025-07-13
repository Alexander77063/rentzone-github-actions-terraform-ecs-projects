#!/bin/bash
set -e

echo "=== RentZone Application Startup ==="

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to wait for database
wait_for_database() {
    local max_attempts=30
    local attempt=1
    
    log "Waiting for database connection..."
    
    while [ $attempt -le $max_attempts ]; do
        if nc -z $(echo $DB_HOST | cut -d':' -f1) 3306 2>/dev/null; then
            log "Database is reachable"
            return 0
        fi
        
        log "Attempt $attempt/$max_attempts: Database not ready, waiting..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    log "ERROR: Database not reachable after $max_attempts attempts"
    return 1
}

# Load environment variables
if [ -f /var/www/html/.env ]; then
    export $(cat /var/www/html/.env | grep -v '^#' | xargs)
    log "Environment variables loaded"
else
    log "ERROR: .env file not found"
    exit 1
fi

# Change to application directory
cd /var/www/html

# Wait for database
if ! wait_for_database; then
    log "WARNING: Database not reachable, continuing without migrations"
fi

# Generate application key if not set
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "" ]; then
    log "Generating application key..."
    php artisan key:generate --force
fi

# Run database migrations if database is available
if nc -z $(echo $DB_HOST | cut -d':' -f1) 3306 2>/dev/null; then
    log "Running database migrations..."
    if php artisan migrate --force; then
        log "Database migrations completed successfully"
    else
        log "WARNING: Database migrations failed, but continuing"
    fi
else
    log "WARNING: Skipping migrations - database not reachable"
fi

# Clear and cache configuration
log "Caching application configuration..."
php artisan config:cache || log "WARNING: Config cache failed"
php artisan route:cache || log "WARNING: Route cache failed"

# Create PHP-FPM run directory
mkdir -p /run/php-fpm

# Start PHP-FPM
log "Starting PHP-FPM..."
php-fpm -D

# Verify PHP-FPM started
if ! pgrep php-fpm > /dev/null; then
    log "ERROR: PHP-FPM failed to start"
    exit 1
fi

log "PHP-FPM started successfully"

# Start Apache in foreground
log "Starting Apache HTTP Server..."
exec /usr/sbin/httpd -D FOREGROUND