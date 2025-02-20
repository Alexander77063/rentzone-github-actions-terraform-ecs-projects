# Use the latest version of the Amazon Linux base image
FROM amazonlinux:2023

# Set build arguments
ARG PERSONAL_ACCESS_TOKEN
ARG GITHUB_USERNAME
ARG REPOSITORY_NAME
ARG DOMAIN_NAME
ARG RDS_ENDPOINT
ARG RDS_DB_NAME
ARG RDS_DB_USERNAME
ARG RDS_DB_PASSWORD

# Set environment variables
ENV PERSONAL_ACCESS_TOKEN=$PERSONAL_ACCESS_TOKEN \
    GITHUB_USERNAME=$GITHUB_USERNAME \
    REPOSITORY_NAME=$REPOSITORY_NAME \
    DOMAIN_NAME=$DOMAIN_NAME \
    RDS_ENDPOINT=$RDS_ENDPOINT \
    RDS_DB_NAME=$RDS_DB_NAME \
    RDS_DB_USERNAME=$RDS_DB_USERNAME \
    RDS_DB_PASSWORD=$RDS_DB_PASSWORD \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Update and install all required packages in a single layer
RUN dnf update -y && \
    dnf install -y \
    glibc-langpack-en \
    glibc-locale-source \
    glibc-common \
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
    php-curl && \
    dnf clean all && \
    localedef -i en_US -f UTF-8 en_US.UTF-8

# Configure PHP and Apache in a single layer
RUN sed -i 's/^memory_limit =.*/memory_limit = 256M/' /etc/php.ini && \
    sed -i 's/^max_execution_time =.*/max_execution_time = 300/' /etc/php.ini && \
    sed -i 's/^expose_php =.*/expose_php = Off/' /etc/php.ini && \
    sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf && \
    echo "ServerTokens Prod" >> /etc/httpd/conf/httpd.conf && \
    echo "ServerSignature Off" >> /etc/httpd/conf/httpd.conf

# Set up application directory
WORKDIR /var/www/html

# Clone repository and set up application in a single layer
RUN git clone https://${PERSONAL_ACCESS_TOKEN}@github.com/${GITHUB_USERNAME}/${REPOSITORY_NAME}.git . && \
    # Create .env file
    echo "APP_URL=https://${DOMAIN_NAME}/" > .env && \
    echo "DB_HOST=${RDS_ENDPOINT}" >> .env && \
    echo "DB_DATABASE=${RDS_DB_NAME}" >> .env && \
    echo "DB_USERNAME=${RDS_DB_USERNAME}" >> .env && \
    echo "DB_PASSWORD=${RDS_DB_PASSWORD}" >> .env && \
    # Set permissions
    chown -R apache:apache /var/www/html && \
    find /var/www/html -type f -exec chmod 644 {} \; && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    chmod -R 775 /var/www/html/bootstrap/cache/ /var/www/html/storage/

# Copy configuration files
COPY AppServiceProvider.php app/Providers/AppServiceProvider.php
COPY start-services.sh /usr/local/bin/start-services.sh

# Set execute permissions for script
RUN chmod +x /usr/local/bin/start-services.sh

# Expose ports
EXPOSE 80 3306

# Start services
CMD ["/usr/local/bin/start-services.sh"]