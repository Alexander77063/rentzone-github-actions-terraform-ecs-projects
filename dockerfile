vFROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install basic packages
RUN apt-get update && \
    apt-get install -y apache2 php php-cli curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Enable PHP module
RUN a2enmod php8.1

WORKDIR /var/www/html

# Create a simple test page first
RUN echo '<?php' > index.php && \
    echo 'echo "<h1>RentZone Application</h1>";' >> index.php && \
    echo 'echo "<p>Status: Running</p>";' >> index.php && \
    echo 'echo "<p>PHP Version: " . phpversion() . "</p>";' >> index.php && \
    echo 'echo "<p>Server Time: " . date("Y-m-d H:i:s") . "</p>";' >> index.php && \
    echo 'if (extension_loaded("mysqli")) {' >> index.php && \
    echo '    echo "<p>MySQL: Available</p>";' >> index.php && \
    echo '} else {' >> index.php && \
    echo '    echo "<p>MySQL: Not Available</p>";' >> index.php && \
    echo '}' >> index.php && \
    echo '?>' >> index.php

# Set permissions
RUN chown -R www-data:www-data /var/www/html

# Create simple startup script
RUN echo '#!/bin/bash' > /usr/local/bin/start.sh && \
    echo 'echo "Starting Apache..."' >> /usr/local/bin/start.sh && \
    echo 'source /etc/apache2/envvars' >> /usr/local/bin/start.sh && \
    echo 'exec /usr/sbin/apache2 -D FOREGROUND' >> /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

EXPOSE 80

CMD ["/usr/local/bin/start.sh"]