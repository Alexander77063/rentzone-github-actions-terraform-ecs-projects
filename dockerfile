FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

ARG DOMAIN_NAME
ARG RDS_ENDPOINT
ARG RDS_DB_NAME
ARG RDS_DB_USERNAME
ARG RDS_DB_PASSWORD

# Install packages
RUN apt-get update && \
    apt-get install -y \
    apache2 \
    php \
    php-cli \
    php-mysql \
    php-mbstring \
    php-xml \
    php-gd \
    php-curl \
    php-bcmath \
    php-zip \
    mysql-client \
    netcat-openbsd \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure PHP
RUN sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php/8.1/apache2/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php/8.1/apache2/php.ini

# Enable Apache modules
RUN a2enmod rewrite && \
    a2enmod php8.1

# Configure Apache for Laravel
RUN echo '<Directory /var/www/html>' > /etc/apache2/conf-available/laravel.conf && \
    echo '    Options Indexes FollowSymLinks' >> /etc/apache2/conf-available/laravel.conf && \
    echo '    AllowOverride All' >> /etc/apache2/conf-available/laravel.conf && \
    echo '    Require all granted' >> /etc/apache2/conf-available/laravel.conf && \
    echo '</Directory>' >> /etc/apache2/conf-available/laravel.conf && \
    a2enconf laravel

WORKDIR /var/www/html

# Copy application code (from GitHub Actions build context)
COPY . .

# Set up Laravel directories and permissions
RUN mkdir -p bootstrap/cache storage/logs storage/framework/sessions storage/framework/views storage/framework/cache && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 775 bootstrap/cache storage

# Create .env file
RUN echo "APP_NAME=RentZone" > .env && \
    echo "APP_ENV=production" >> .env && \
    echo "APP_KEY=" >> .env && \
    echo "APP_DEBUG=false" >> .env && \
    echo "APP_URL=https://${DOMAIN_NAME}/" >> .env && \
    echo "LOG_CHANNEL=stderr" >> .env && \
    echo "LOG_LEVEL=info" >> .env && \
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

# Copy AppServiceProvider if it exists
COPY AppServiceProvider.php app/Providers/AppServiceProvider.php 2>/dev/null || echo "AppServiceProvider.php not found, using default"

# Create startup script
RUN echo '#!/bin/bash' > /usr/local/bin/start-services.sh && \
    echo 'set -e' >> /usr/local/bin/start-services.sh && \
    echo 'echo "=== Starting RentZone Application ==="' >> /usr/local/bin/start-services.sh && \
    echo 'cd /var/www/html' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Generate application key' >> /usr/local/bin/start-services.sh && \
    echo 'echo "Generating application key..."' >> /usr/local/bin/start-services.sh && \
    echo 'php artisan key:generate --force' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Test database connection' >> /usr/local/bin/start-services.sh && \
    echo 'echo "Testing database connection..."' >> /usr/local/bin/start-services.sh && \
    echo 'DB_HOST_CLEAN=$(echo ${DB_HOST} | cut -d: -f1)' >> /usr/local/bin/start-services.sh && \
    echo 'timeout 30 bash -c "until nc -z ${DB_HOST_CLEAN} 3306; do sleep 1; done" || echo "Database not immediately available"' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Run migrations if database is available' >> /usr/local/bin/start-services.sh && \
    echo 'if nc -z ${DB_HOST_CLEAN} 3306; then' >> /usr/local/bin/start-services.sh && \
    echo '    echo "Running database migrations..."' >> /usr/local/bin/start-services.sh && \
    echo '    php artisan migrate --force || echo "Migration failed, continuing..."' >> /usr/local/bin/start-services.sh && \
    echo 'else' >> /usr/local/bin/start-services.sh && \
    echo '    echo "Database not available, skipping migrations"' >> /usr/local/bin/start-services.sh && \
    echo 'fi' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Start Apache' >> /usr/local/bin/start-services.sh && \
    echo 'echo "Starting Apache web server..."' >> /usr/local/bin/start-services.sh && \
    echo 'source /etc/apache2/envvars' >> /usr/local/bin/start-services.sh && \
    echo 'exec /usr/sbin/apache2 -D FOREGROUND' >> /usr/local/bin/start-services.sh && \
    chmod +x /usr/local/bin/start-services.sh

EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

CMD ["/usr/local/bin/start-services.sh"]