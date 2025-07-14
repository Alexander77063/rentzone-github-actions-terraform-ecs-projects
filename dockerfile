FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

ARG DOMAIN_NAME
ARG RDS_ENDPOINT
ARG RDS_DB_NAME
ARG RDS_DB_USERNAME
ARG RDS_DB_PASSWORD

# Install packages including unzip
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
    php-intl \
    php-dom \
    mysql-client \
    netcat-openbsd \
    curl \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure PHP
RUN sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php/8.1/apache2/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php/8.1/apache2/php.ini && \
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' /etc/php/8.1/apache2/php.ini && \
    sed -i 's/post_max_size = .*/post_max_size = 64M/' /etc/php/8.1/apache2/php.ini

# Enable Apache modules
RUN a2enmod rewrite && a2enmod php8.1

# Configure Apache Virtual Host for Laravel
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/laravel.conf && \
    echo '    ServerName www.alexander77063.co.uk' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    DocumentRoot /var/www/html/public' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    ' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    <Directory /var/www/html>' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        AllowOverride All' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    </Directory>' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    ' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    <Directory /var/www/html/public>' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        Options Indexes FollowSymLinks' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        AllowOverride All' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        Require all granted' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        ' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        # Handle Laravel routing' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        RewriteEngine On' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        RewriteCond %{REQUEST_FILENAME} !-d' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        RewriteCond %{REQUEST_FILENAME} !-f' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        RewriteRule ^ index.php [L]' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    </Directory>' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    ' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    ErrorLog ${APACHE_LOG_DIR}/laravel_error.log' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    CustomLog ${APACHE_LOG_DIR}/laravel_access.log combined' >> /etc/apache2/sites-available/laravel.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/laravel.conf

# Disable default site and enable Laravel site
RUN a2dissite 000-default && \
    a2ensite laravel

WORKDIR /var/www/html

# Remove default Apache files
RUN rm -rf /var/www/html/*

# Copy all files from build context
COPY . .

# Extract Laravel application from rentzone.zip
RUN if [ -f "rentzone.zip" ]; then \
        echo "Extracting Laravel application from rentzone.zip..."; \
        unzip -q rentzone.zip; \
        if [ -d "rentzone" ]; then \
            cp -r rentzone/* . 2>/dev/null || true; \
            cp -r rentzone/.* . 2>/dev/null || true; \
            rm -rf rentzone; \
        fi; \
        rm -f rentzone.zip; \
        echo "Laravel application extracted successfully"; \
    fi

# Set proper permissions for Laravel
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 775 storage bootstrap/cache && \
    chmod 644 .env 2>/dev/null || true

# Create/Update .env file with production settings
RUN echo "APP_NAME=RentZone" > .env && \
    echo "APP_ENV=production" >> .env && \
    echo "APP_KEY=" >> .env && \
    echo "APP_DEBUG=false" >> .env && \
    echo "APP_URL=https://${DOMAIN_NAME}/" >> .env && \
    echo "" >> .env && \
    echo "LOG_CHANNEL=stderr" >> .env && \
    echo "LOG_DEPRECATIONS_CHANNEL=null" >> .env && \
    echo "LOG_LEVEL=error" >> .env && \
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
    echo "SESSION_LIFETIME=120" >> .env && \
    echo "" >> .env && \
    echo "MEMCACHED_HOST=127.0.0.1" >> .env && \
    echo "" >> .env && \
    echo "REDIS_HOST=127.0.0.1" >> .env && \
    echo "REDIS_PASSWORD=null" >> .env && \
    echo "REDIS_PORT=6379" >> .env && \
    echo "" >> .env && \
    echo "MAIL_MAILER=smtp" >> .env && \
    echo "MAIL_HOST=mailhog" >> .env && \
    echo "MAIL_PORT=1025" >> .env && \
    echo "MAIL_USERNAME=null" >> .env && \
    echo "MAIL_PASSWORD=null" >> .env && \
    echo "MAIL_ENCRYPTION=null" >> .env && \
    echo "MAIL_FROM_ADDRESS=hello@example.com" >> .env && \
    echo "MAIL_FROM_NAME=\"\${APP_NAME}\"" >> .env

# Create comprehensive startup script
RUN echo '#!/bin/bash' > /usr/local/bin/start-services.sh && \
    echo 'set -e' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo 'echo "=== Starting RentZone Laravel Application ==="' >> /usr/local/bin/start-services.sh && \
    echo 'cd /var/www/html' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Generate application key if not set' >> /usr/local/bin/start-services.sh && \
    echo 'if grep -q "APP_KEY=$" .env || grep -q "APP_KEY=\"\"" .env; then' >> /usr/local/bin/start-services.sh && \
    echo '    echo "Generating Laravel application key..."' >> /usr/local/bin/start-services.sh && \
    echo '    php artisan key:generate --force' >> /usr/local/bin/start-services.sh && \
    echo 'else' >> /usr/local/bin/start-services.sh && \
    echo '    echo "Application key already set"' >> /usr/local/bin/start-services.sh && \
    echo 'fi' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Clear and optimize Laravel cache' >> /usr/local/bin/start-services.sh && \
    echo 'echo "Optimizing Laravel application..."' >> /usr/local/bin/start-services.sh && \
    echo 'php artisan config:cache' >> /usr/local/bin/start-services.sh && \
    echo 'php artisan route:cache' >> /usr/local/bin/start-services.sh && \
    echo 'php artisan view:cache || echo "View cache failed, continuing..."' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Database operations' >> /usr/local/bin/start-services.sh && \
    echo 'DB_HOST_CLEAN=$(echo ${DB_HOST} | cut -d: -f1)' >> /usr/local/bin/start-services.sh && \
    echo 'echo "Checking database connection to ${DB_HOST_CLEAN}:3306..."' >> /usr/local/bin/start-services.sh && \
    echo 'if timeout 30 bash -c "until nc -z ${DB_HOST_CLEAN} 3306; do sleep 2; done"; then' >> /usr/local/bin/start-services.sh && \
    echo '    echo "Database is available, running migrations..."' >> /usr/local/bin/start-services.sh && \
    echo '    php artisan migrate --force || echo "Migration failed, but continuing..."' >> /usr/local/bin/start-services.sh && \
    echo 'else' >> /usr/local/bin/start-services.sh && \
    echo '    echo "Database not available within timeout, skipping migrations"' >> /usr/local/bin/start-services.sh && \
    echo 'fi' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Start Apache' >> /usr/local/bin/start-services.sh && \
    echo 'echo "Starting Apache web server..."' >> /usr/local/bin/start-services.sh && \
    echo 'echo "Laravel application will be available at: https://www.alexander77063.co.uk"' >> /usr/local/bin/start-services.sh && \
    echo 'source /etc/apache2/envvars' >> /usr/local/bin/start-services.sh && \
    echo 'exec /usr/sbin/apache2 -D FOREGROUND' >> /usr/local/bin/start-services.sh && \
    chmod +x /usr/local/bin/start-services.sh

EXPOSE 80

# Health check for Laravel
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

CMD ["/usr/local/bin/start-services.sh"]