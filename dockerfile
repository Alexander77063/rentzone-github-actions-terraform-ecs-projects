FROM public.ecr.aws/amazonlinux/amazonlinux:2023

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

ARG PERSONAL_ACCESS_TOKEN
ARG GITHUB_USERNAME
ARG REPOSITORY_NAME
ARG DOMAIN_NAME
ARG RDS_ENDPOINT
ARG RDS_DB_NAME
ARG RDS_DB_USERNAME
ARG RDS_DB_PASSWORD

ENV PERSONAL_ACCESS_TOKEN=$PERSONAL_ACCESS_TOKEN \
    GITHUB_USERNAME=$GITHUB_USERNAME \
    REPOSITORY_NAME=$REPOSITORY_NAME \
    DOMAIN_NAME=$DOMAIN_NAME \
    RDS_ENDPOINT=$RDS_ENDPOINT \
    RDS_DB_NAME=$RDS_DB_NAME \
    RDS_DB_USERNAME=$RDS_DB_USERNAME \
    RDS_DB_PASSWORD=$RDS_DB_PASSWORD

# Install all required packages in a single layer
RUN dnf update -y && \
    dnf install -y \
    git \
    httpd \
    php \
    php-cli \
    php-fpm \
    php-mysqlnd \
    php-bcmath \
    php-ctype \
    php-fileinfo \
    php-json \
    php-mbstring \
    php-openssl \
    php-pdo \
    php-gd \
    php-tokenizer \
    php-xml \
    php-curl \
    mysql \
    netcat && \
    dnf clean all

# Configure PHP
RUN sed -i 's/^memory_limit =.*/memory_limit = 256M/' /etc/php.ini && \
    sed -i 's/^max_execution_time =.*/max_execution_time = 300/' /etc/php.ini

# Configure Apache
RUN sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

WORKDIR /var/www/html

# Clone the repository and create required directories
RUN git clone https://${PERSONAL_ACCESS_TOKEN}@github.com/${GITHUB_USERNAME}/${REPOSITORY_NAME}.git . && \
    mkdir -p bootstrap/cache storage/logs && \
    chown -R apache:apache /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 775 bootstrap/cache storage

# Create environment file with better error handling
RUN echo "APP_NAME=RentZone" > .env && \
    echo "APP_ENV=production" >> .env && \
    echo "APP_KEY=" >> .env && \
    echo "APP_DEBUG=false" >> .env && \
    echo "APP_URL=https://${DOMAIN_NAME}/" >> .env && \
    echo "" >> .env && \
    echo "LOG_CHANNEL=stderr" >> .env && \
    echo "LOG_DEPRECATIONS_CHANNEL=null" >> .env && \
    echo "LOG_LEVEL=debug" >> .env && \
    echo "" >> .env && \
    echo "DB_CONNECTION=mysql" >> .env && \
    echo "DB_HOST=${RDS_ENDPOINT}" >> .env && \
    echo "DB_PORT=3306" >> .env && \
    echo "DB_DATABASE=${RDS_DB_NAME}" >> .env && \
    echo "DB_USERNAME=${RDS_DB_USERNAME}" >> .env && \
    echo "DB_PASSWORD=${RDS_DB_PASSWORD}" >> .env && \
    echo "" >> .env && \
    echo "BROADCAST_DRIVER=log" >> .env && \
    echo "CACHE_DRIVER=file" >> .env && \
    echo "FILESYSTEM_DISK=local" >> .env && \
    echo "QUEUE_CONNECTION=sync" >> .env && \
    echo "SESSION_DRIVER=file" >> .env && \
    echo "SESSION_LIFETIME=120" >> .env

# Copy provider file
COPY AppServiceProvider.php app/Providers/AppServiceProvider.php

# Create improved startup script
RUN cat > /usr/local/bin/start-services.sh << 'EOF'
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
EOF

# Make startup script executable
RUN chmod +x /usr/local/bin/start-services.sh

EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

CMD ["/usr/local/bin/start-services.sh"]