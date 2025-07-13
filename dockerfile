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

# Install packages
RUN dnf update -y && \
    dnf install -y \
    git \
    httpd \
    php \
    php-cli \
    php-fpm \
    php-mysqlnd \
    php-bcmath \
    php-fileinfo \
    php-mbstring \
    php-openssl \
    php-pdo \
    php-gd \
    php-xml \
    php-curl \
    mysql \
    nmap-ncat && \
    dnf clean all

# Configure PHP and Apache
RUN sed -i 's/^memory_limit =.*/memory_limit = 256M/' /etc/php.ini && \
    sed -i 's/^max_execution_time =.*/max_execution_time = 300/' /etc/php.ini && \
    sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

WORKDIR /var/www/html

# Clone repository
RUN git clone https://${PERSONAL_ACCESS_TOKEN}@github.com/${GITHUB_USERNAME}/${REPOSITORY_NAME}.git . && \
    mkdir -p bootstrap/cache storage/logs && \
    chown -R apache:apache /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 775 bootstrap/cache storage

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

COPY AppServiceProvider.php app/Providers/AppServiceProvider.php

# Create simple startup script
RUN echo '#!/bin/bash' > /usr/local/bin/start-services.sh && \
    echo 'cd /var/www/html' >> /usr/local/bin/start-services.sh && \
    echo 'php artisan key:generate --force' >> /usr/local/bin/start-services.sh && \
    echo 'mkdir -p /run/php-fpm' >> /usr/local/bin/start-services.sh && \
    echo 'php-fpm -D' >> /usr/local/bin/start-services.sh && \
    echo '/usr/sbin/httpd -D FOREGROUND' >> /usr/local/bin/start-services.sh && \
    chmod +x /usr/local/bin/start-services.sh

EXPOSE 80

CMD ["/usr/local/bin/start-services.sh"]