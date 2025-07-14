# Use the latest version of the Amazon Linux base image
FROM amazonlinux:2

# Update all installed packages to their latest versions
RUN yum update -y 

# Install required packages
RUN yum install -y unzip wget httpd git

# Install PHP and various extensions
RUN amazon-linux-extras enable php7.4 && \
    yum clean metadata && \
    yum install -y \
    php \
    php-common \
    php-pear \
    php-cgi \
    php-curl \
    php-mbstring \
    php-gd \
    php-mysqlnd \
    php-gettext \
    php-json \
    php-xml \
    php-fpm \
    php-intl \
    php-zip

# Download and install MySQL repository
RUN wget https://repo.mysql.com/mysql80-community-release-el7-3.noarch.rpm && \
    rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 && \
    yum localinstall mysql80-community-release-el7-3.noarch.rpm -y && \
    yum install mysql-community-server -y

# Change directory to the html directory
WORKDIR /var/www/html

# Set the build argument directive
ARG PERSONAL_ACCESS_TOKEN
ARG GITHUB_USERNAME
ARG REPOSITORY_NAME
ARG WEB_FILE_ZIP
ARG WEB_FILE_UNZIP
ARG DOMAIN_NAME
ARG RDS_ENDPOINT
ARG RDS_DB_NAME
ARG RDS_DB_USERNAME
ARG RDS_DB_PASSWORD

# Use the build argument to set environment variables 
ENV PERSONAL_ACCESS_TOKEN=$PERSONAL_ACCESS_TOKEN
ENV GITHUB_USERNAME=$GITHUB_USERNAME
ENV REPOSITORY_NAME=$REPOSITORY_NAME
ENV WEB_FILE_ZIP=$WEB_FILE_ZIP
ENV WEB_FILE_UNZIP=$WEB_FILE_UNZIP
ENV DOMAIN_NAME=$DOMAIN_NAME
ENV RDS_ENDPOINT=$RDS_ENDPOINT
ENV RDS_DB_NAME=$RDS_DB_NAME
ENV RDS_DB_USERNAME=$RDS_DB_USERNAME
ENV RDS_DB_PASSWORD=$RDS_DB_PASSWORD

# Clone the GitHub repository
RUN git clone https://$PERSONAL_ACCESS_TOKEN@github.com/$GITHUB_USERNAME/$REPOSITORY_NAME.git

# Unzip the zip folder containing the web files
RUN unzip $REPOSITORY_NAME/$WEB_FILE_ZIP -d $REPOSITORY_NAME/

# Copy the web files into the HTML directory
RUN cp -av $REPOSITORY_NAME/$WEB_FILE_UNZIP/. /var/www/html

# Remove the repository we cloned
RUN rm -rf $REPOSITORY_NAME

# Enable the mod_rewrite setting in the httpd.conf file
RUN sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

# Give appropriate permissions
RUN chmod -R 755 /var/www/html && \
    chmod -R 775 storage/ && \
    chown -R apache:apache /var/www/html

# Configure Laravel environment
RUN sed -i '/^APP_ENV=/ s/=.*$/=production/' .env && \
    sed -i "/^APP_URL=/ s/=.*$/=https:\/\/$DOMAIN_NAME\//" .env && \
    sed -i "/^DB_HOST=/ s/=.*$/=$RDS_ENDPOINT/" .env && \
    sed -i "/^DB_DATABASE=/ s/=.*$/=$RDS_DB_NAME/" .env && \
    sed -i "/^DB_USERNAME=/ s/=.*$/=$RDS_DB_USERNAME/" .env && \
    sed -i "/^DB_PASSWORD=/ s/=.*$/=$RDS_DB_PASSWORD/" .env

# Copy the AppServiceProvider.php file
COPY AppServiceProvider.php app/Providers/AppServiceProvider.php

# Expose the default Apache port
EXPOSE 80

# Start Apache
ENTRYPOINT ["/usr/sbin/httpd", "-D", "FOREGROUND"]