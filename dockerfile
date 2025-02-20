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
    php-curl && \
    dnf clean all

RUN sed -i 's/^memory_limit =.*/memory_limit = 256M/' /etc/php.ini && \
    sed -i 's/^max_execution_time =.*/max_execution_time = 300/' /etc/php.ini

RUN sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

WORKDIR /var/www/html

RUN git clone https://${PERSONAL_ACCESS_TOKEN}@github.com/${GITHUB_USERNAME}/${REPOSITORY_NAME}.git .

RUN chown -R apache:apache /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 775 /var/www/html/bootstrap/cache/ /var/www/html/storage/

RUN echo "APP_URL=https://${DOMAIN_NAME}/" > .env && \
    echo "DB_HOST=${RDS_ENDPOINT}" >> .env && \
    echo "DB_DATABASE=${RDS_DB_NAME}" >> .env && \
    echo "DB_USERNAME=${RDS_DB_USERNAME}" >> .env && \
    echo "DB_PASSWORD=${RDS_DB_PASSWORD}" >> .env

COPY AppServiceProvider.php app/Providers/AppServiceProvider.php

EXPOSE 80 3306

COPY start-services.sh /usr/local/bin/start-services.sh
RUN chmod +x /usr/local/bin/start-services.sh

CMD ["/usr/local/bin/start-services.sh"]