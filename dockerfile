FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ARG DOMAIN_NAME
ARG RDS_ENDPOINT
ARG RDS_DB_NAME
ARG RDS_DB_USERNAME
ARG RDS_DB_PASSWORD

# Install packages
RUN apt-get update && \
    apt-get install -y apache2 php php-cli php-mysql curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Enable PHP module
RUN a2enmod php8.1

WORKDIR /var/www/html

# Remove default Apache page
RUN rm -f /var/www/html/index.html

# Copy application code
COPY . .

# Create a test index.php to verify Laravel is working
RUN echo '<?php' > index.php && \
    echo 'echo "<h1>🚀 RentZone Application</h1>";' >> index.php && \
    echo 'echo "<p><strong>Status:</strong> Running Successfully!</p>";' >> index.php && \
    echo 'echo "<p><strong>PHP Version:</strong> " . phpversion() . "</p>";' >> index.php && \
    echo 'echo "<p><strong>Server Time:</strong> " . date("Y-m-d H:i:s") . "</p>";' >> index.php && \
    echo 'echo "<p><strong>Domain:</strong> " . $_SERVER["HTTP_HOST"] . "</p>";' >> index.php && \
    echo 'if (file_exists("public/index.php")) {' >> index.php && \
    echo '    echo "<p><strong>Laravel:</strong> ✅ public/index.php found</p>";' >> index.php && \
    echo '} else {' >> index.php && \
    echo '    echo "<p><strong>Laravel:</strong> ❌ public/index.php not found</p>";' >> index.php && \
    echo '}' >> index.php && \
    echo 'if (extension_loaded("mysqli")) {' >> index.php && \
    echo '    echo "<p><strong>MySQL:</strong> ✅ Available</p>";' >> index.php && \
    echo '} else {' >> index.php && \
    echo '    echo "<p><strong>MySQL:</strong> ❌ Not Available</p>";' >> index.php && \
    echo '}' >> index.php && \
    echo 'echo "<hr>";' >> index.php && \
    echo 'echo "<h3>Application Files:</h3>";' >> index.php && \
    echo 'echo "<pre>";' >> index.php && \
    echo 'print_r(scandir("/var/www/html"));' >> index.php && \
    echo 'echo "</pre>";' >> index.php && \
    echo '?>' >> index.php

# Set permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Simple startup
RUN echo '#!/bin/bash' > /usr/local/bin/start.sh && \
    echo 'source /etc/apache2/envvars' >> /usr/local/bin/start.sh && \
    echo 'exec /usr/sbin/apache2 -D FOREGROUND' >> /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

EXPOSE 80

CMD ["/usr/local/bin/start.sh"]