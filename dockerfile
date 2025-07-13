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
    mysql-client \
    netcat-openbsd \
    curl \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure PHP
RUN sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php/8.1/apache2/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php/8.1/apache2/php.ini

# Enable Apache modules
RUN a2enmod rewrite && a2enmod php8.1

# Configure Apache for Laravel
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/laravel.conf && \
    echo '    DocumentRoot /var/www/html/public' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    <Directory /var/www/html/public>' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        Options Indexes FollowSymLinks' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        AllowOverride All' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        Require all granted' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    </Directory>' >> /etc/apache2/sites-available/laravel.conf && \
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
        echo "Zip contents:"; \
        ls -la; \
        if [ -d "rentzone" ]; then \
            echo "Moving files from rentzone/ directory..."; \
            mv rentzone/* .; \
            mv rentzone/.* . 2>/dev/null || true; \
            rm -rf rentzone; \
        fi; \
        rm -f rentzone.zip; \
        echo "Laravel application extracted successfully"; \
    else \
        echo "rentzone.zip not found"; \
    fi

# List files after extraction for debugging
RUN echo "Files after extraction:" && ls -la

# Create required Laravel directories if they don't exist
RUN mkdir -p bootstrap/cache storage/logs storage/framework/sessions storage/framework/views storage/framework/cache

# Set permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 775 bootstrap/cache storage 2>/dev/null || true

# Create .env file
RUN echo "APP_NAME=RentZone" > .env && \
    echo "APP_ENV=production" >> .env && \
    echo "APP_KEY=" >> .env && \
    echo "APP_DEBUG=false" >> .env && \
    echo "APP_URL=https://${DOMAIN_NAME}/" >> .env && \
    echo "LOG_CHANNEL=stderr" >> .env && \
    echo "DB_CONNECTION=mysql" >> .env && \
    echo "DB_HOST=${RDS_ENDPOINT}" >> .env && \
    echo "DB_PORT=3306" >> .env && \
    echo "DB_DATABASE=${RDS_DB_NAME}" >> .env && \
    echo "DB_USERNAME=${RDS_DB_USERNAME}" >> .env && \
    echo "DB_PASSWORD=${RDS_DB_PASSWORD}" >> .env

# Create startup script
RUN echo '#!/bin/bash' > /usr/local/bin/start-services.sh && \
    echo 'set -e' >> /usr/local/bin/start-services.sh && \
    echo 'cd /var/www/html' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Debug: Show current directory contents' >> /usr/local/bin/start-services.sh && \
    echo 'echo "=== Current Directory Contents ==="' >> /usr/local/bin/start-services.sh && \
    echo 'ls -la' >> /usr/local/bin/start-services.sh && \
    echo 'echo "=== Public Directory Contents ==="' >> /usr/local/bin/start-services.sh && \
    echo 'ls -la public/ 2>/dev/null || echo "public directory not found"' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Generate Laravel application key if artisan exists' >> /usr/local/bin/start-services.sh && \
    echo 'if [ -f "artisan" ]; then' >> /usr/local/bin/start-services.sh && \
    echo '    echo "Generating Laravel application key..."' >> /usr/local/bin/start-services.sh && \
    echo '    php artisan key:generate --force' >> /usr/local/bin/start-services.sh && \
    echo 'else' >> /usr/local/bin/start-services.sh && \
    echo '    echo "Warning: artisan file not found - not a Laravel application"' >> /usr/local/bin/start-services.sh && \
    echo 'fi' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Try database operations if available' >> /usr/local/bin/start-services.sh && \
    echo 'DB_HOST_CLEAN=$(echo ${DB_HOST} | cut -d: -f1)' >> /usr/local/bin/start-services.sh && \
    echo 'if nc -z ${DB_HOST_CLEAN} 3306 2>/dev/null && [ -f "artisan" ]; then' >> /usr/local/bin/start-services.sh && \
    echo '    echo "Database available, running migrations..."' >> /usr/local/bin/start-services.sh && \
    echo '    php artisan migrate --force || echo "Migration failed, continuing..."' >> /usr/local/bin/start-services.sh && \
    echo 'else' >> /usr/local/bin/start-services.sh && \
    echo '    echo "Database not available or not Laravel app, skipping migrations"' >> /usr/local/bin/start-services.sh && \
    echo 'fi' >> /usr/local/bin/start-services.sh && \
    echo '' >> /usr/local/bin/start-services.sh && \
    echo '# Start Apache' >> /usr/local/bin/start-services.sh && \
    echo 'echo "Starting Apache web server..."' >> /usr/local/bin/start-services.sh && \
    echo 'source /etc/apache2/envvars' >> /usr/local/bin/start-services.sh && \
    echo 'exec /usr/sbin/apache2 -D FOREGROUND' >> /usr/local/bin/start-services.sh && \
    chmod +x /usr/local/bin/start-services.sh

EXPOSE 80

CMD ["/usr/local/bin/start-services.sh"]