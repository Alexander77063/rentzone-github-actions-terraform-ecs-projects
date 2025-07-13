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

# Configure PHP and Apache
RUN sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php/8.1/apache2/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php/8.1/apache2/php.ini && \
    a2enmod rewrite && a2enmod php8.1

WORKDIR /var/www/html

# Remove default Apache files
RUN rm -rf /var/www/html/*

# Copy all files from build context
COPY . .

# Debug and extract ZIP file
RUN echo "=== DEBUGGING ZIP EXTRACTION ===" && \
    echo "Current directory:" && pwd && \
    echo "Files before extraction:" && ls -la && \
    echo "" && \
    if [ -f "rentzone.zip" ]; then \
        echo "ZIP file found! Checking contents..." && \
        unzip -l rentzone.zip && \
        echo "" && \
        echo "Extracting ZIP file..." && \
        unzip -q rentzone.zip && \
        echo "Files after extraction:" && ls -la && \
        echo "" && \
        echo "Looking for Laravel files..." && \
        find . -name "artisan" -type f && \
        find . -name "public" -type d && \
        echo "" && \
        if [ -d "rentzone" ]; then \
            echo "Found rentzone directory, moving contents..." && \
            ls -la rentzone/ && \
            cp -r rentzone/* . 2>/dev/null || true && \
            cp -r rentzone/.* . 2>/dev/null || true && \
            rm -rf rentzone && \
            echo "Files after moving from rentzone/:" && ls -la; \
        fi && \
        rm -f rentzone.zip; \
    else \
        echo "No rentzone.zip found!"; \
    fi && \
    echo "=== END ZIP EXTRACTION DEBUG ==="

# Create a comprehensive test index.php
RUN echo '<?php' > index.php && \
    echo 'echo "<h1>🚀 RentZone Application Debug</h1>";' >> index.php && \
    echo 'echo "<p><strong>Status:</strong> Container Running</p>";' >> index.php && \
    echo 'echo "<p><strong>PHP Version:</strong> " . phpversion() . "</p>";' >> index.php && \
    echo 'echo "<p><strong>Server Time:</strong> " . date("Y-m-d H:i:s") . "</p>";' >> index.php && \
    echo 'echo "<p><strong>Domain:</strong> " . $_SERVER["HTTP_HOST"] . "</p>";' >> index.php && \
    echo 'echo "<hr>";' >> index.php && \
    echo 'echo "<h3>Laravel Detection:</h3>";' >> index.php && \
    echo 'if (file_exists("artisan")) {' >> index.php && \
    echo '    echo "<p>✅ <strong>artisan found:</strong> Laravel application detected</p>";' >> index.php && \
    echo '} else {' >> index.php && \
    echo '    echo "<p>❌ <strong>artisan not found:</strong> Not a Laravel application</p>";' >> index.php && \
    echo '}' >> index.php && \
    echo 'if (file_exists("public/index.php")) {' >> index.php && \
    echo '    echo "<p>✅ <strong>public/index.php found:</strong> Laravel public directory exists</p>";' >> index.php && \
    echo '} else {' >> index.php && \
    echo '    echo "<p>❌ <strong>public/index.php not found:</strong> Laravel public directory missing</p>";' >> index.php && \
    echo '}' >> index.php && \
    echo 'if (file_exists("composer.json")) {' >> index.php && \
    echo '    echo "<p>✅ <strong>composer.json found:</strong> PHP project detected</p>";' >> index.php && \
    echo '} else {' >> index.php && \
    echo '    echo "<p>❌ <strong>composer.json not found:</strong> No PHP project</p>";' >> index.php && \
    echo '}' >> index.php && \
    echo 'echo "<hr>";' >> index.php && \
    echo 'echo "<h3>Directory Contents:</h3>";' >> index.php && \
    echo 'echo "<pre>";' >> index.php && \
    echo '$files = scandir("/var/www/html");' >> index.php && \
    echo 'foreach($files as $file) {' >> index.php && \
    echo '    if($file != "." && $file != "..") {' >> index.php && \
    echo '        $path = "/var/www/html/" . $file;' >> index.php && \
    echo '        $type = is_dir($path) ? "[DIR]" : "[FILE]";' >> index.php && \
    echo '        echo $type . " " . $file . "\n";' >> index.php && \
    echo '    }' >> index.php && \
    echo '}' >> index.php && \
    echo 'echo "</pre>";' >> index.php && \
    echo 'if(is_dir("public")) {' >> index.php && \
    echo '    echo "<h3>Public Directory Contents:</h3>";' >> index.php && \
    echo '    echo "<pre>";' >> index.php && \
    echo '    $publicFiles = scandir("/var/www/html/public");' >> index.php && \
    echo '    foreach($publicFiles as $file) {' >> index.php && \
    echo '        if($file != "." && $file != "..") {' >> index.php && \
    echo '            echo $file . "\n";' >> index.php && \
    echo '        }' >> index.php && \
    echo '    }' >> index.php && \
    echo '    echo "</pre>";' >> index.php && \
    echo '}' >> index.php && \
    echo '?>' >> index.php

# Set permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Simple startup
RUN echo '#!/bin/bash' > /usr/local/bin/start.sh && \
    echo 'echo "Starting Apache with debug info..."' >> /usr/local/bin/start.sh && \
    echo 'cd /var/www/html' >> /usr/local/bin/start.sh && \
    echo 'echo "Current directory contents:"' >> /usr/local/bin/start.sh && \
    echo 'ls -la' >> /usr/local/bin/start.sh && \
    echo 'source /etc/apache2/envvars' >> /usr/local/bin/start.sh && \
    echo 'exec /usr/sbin/apache2 -D FOREGROUND' >> /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

EXPOSE 80

CMD ["/usr/local/bin/start.sh"]