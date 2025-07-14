
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
    php-intl \
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

# Configure Apache Virtual Host for Laravel
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/laravel.conf && \
    echo '    DocumentRoot /var/www/html/public' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    <Directory /var/www/html/public>' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        Options Indexes FollowSymLinks' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        AllowOverride All' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        Require all granted' >> /etc/apache2/sites-available/laravel.conf && \
    echo '        DirectoryIndex index.php' >> /etc/apache2/sites-available/laravel.conf && \
    echo '    </Directory>' >> /etc/apache2/sites-available/laravel.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/laravel.conf

# Disable default site and enable Laravel
RUN a2dissite 000-default && a2ensite laravel

WORKDIR /var/www/html

# Remove default files
RUN rm -rf /var/www/html/*

# Copy only what we need, excluding problematic files
COPY rentzone.zip .

# Extract and selectively copy Laravel files
RUN echo "=== Extracting Laravel Application ===" && \
    if [ -f "rentzone.zip" ]; then \
        echo "Contents of ZIP file:"; \
        unzip -l rentzone.zip; \
        echo ""; \
        echo "Extracting ZIP..."; \
        unzip -q rentzone.zip; \
        echo ""; \
        if [ -d "rentzone" ]; then \
            echo "Files in rentzone directory:"; \
            ls -la rentzone/; \
            echo ""; \
            echo "Copying Laravel files selectively..."; \
            # Copy Laravel directories and essential files \
            cp -r rentzone/app . 2>/dev/null || true; \
            cp -r rentzone/bootstrap . 2>/dev/null || true; \
            cp -r rentzone/config . 2>/dev/null || true; \
            cp -r rentzone/database . 2>/dev/null || true; \
            cp -r rentzone/public . 2>/dev/null || true; \
            cp -r rentzone/resources . 2>/dev/null || true; \
            cp -r rentzone/routes . 2>/dev/null || true; \
            cp -r rentzone/storage . 2>/dev/null || true; \
            cp -r rentzone/tests . 2>/dev/null || true; \
            cp -r rentzone/vendor . 2>/dev/null || true; \
            # Copy Laravel files but NOT index.php \
            cp rentzone/artisan . 2>/dev/null || true; \
            cp rentzone/composer.json . 2>/dev/null || true; \
            cp rentzone/composer.lock . 2>/dev/null || true; \
            cp rentzone/package.json . 2>/dev/null || true; \
            cp rentzone/.htaccess . 2>/dev/null || true; \
            # DO NOT copy index.php from root \
            echo "Skipping root index.php from ZIP"; \
            rm -rf rentzone; \
        else \
            echo "No rentzone directory found, copying all files except index.php"; \
            # Copy everything except index.php \
            find . -name "index.php" -not -path "./public/*" -delete; \
        fi; \
        rm -f rentzone.zip; \
    else \
        echo "No rentzone.zip found"; \
    fi

# Ensure we have a clean state
RUN echo "=== Final Cleanup ===" && \
    # Remove any remaining debug files \
    rm -f index.php start-services.sh dockerfile 2>/dev/null || true && \
    echo "Files after cleanup:" && ls -la && \
    echo "Public directory:" && ls -la public/ 2>/dev/null || echo "No public directory"

# Set Laravel permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 775 storage bootstrap/cache 2>/dev/null || true

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

# Create startup script with validation
RUN echo '#!/bin/bash' > /usr/local/bin/start.sh && \
    echo 'set -e' >> /usr/local/bin/start.sh && \
    echo 'cd /var/www/html' >> /usr/local/bin/start.sh && \
    echo 'echo "=== Starting Laravel Application ==="' >> /usr/local/bin/start.sh && \
    echo 'echo "Final directory check:"' >> /usr/local/bin/start.sh && \
    echo 'ls -la' >> /usr/local/bin/start.sh && \
    echo 'if [ -f "index.php" ]; then' >> /usr/local/bin/start.sh && \
    echo '    echo "ERROR: Debug index.php still exists, removing..."' >> /usr/local/bin/start.sh && \
    echo '    rm -f index.php' >> /usr/local/bin/start.sh && \
    echo 'fi' >> /usr/local/bin/start.sh && \
    echo 'if [ ! -f "public/index.php" ]; then' >> /usr/local/bin/start.sh && \
    echo '    echo "ERROR: Laravel public/index.php missing!"' >> /usr/local/bin/start.sh && \
    echo '    exit 1' >> /usr/local/bin/start.sh && \
    echo 'fi' >> /usr/local/bin/start.sh && \
    echo 'php artisan key:generate --force' >> /usr/local/bin/start.sh && \
    echo 'php artisan config:cache' >> /usr/local/bin/start.sh && \
    echo 'if nc -z $(echo ${DB_HOST} | cut -d: -f1) 3306 2>/dev/null; then' >> /usr/local/bin/start.sh && \
    echo '    php artisan migrate --force || echo "Migration failed"' >> /usr/local/bin/start.sh && \
    echo 'fi' >> /usr/local/bin/start.sh && \
    echo 'echo "Starting Apache - serving Laravel from /var/www/html/public"' >> /usr/local/bin/start.sh && \
    echo 'source /etc/apache2/envvars' >> /usr/local/bin/start.sh && \
    echo 'exec /usr/sbin/apache2 -D FOREGROUND' >> /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

EXPOSE 80

CMD ["/usr/local/bin/start.sh"]