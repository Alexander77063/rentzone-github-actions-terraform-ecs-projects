#!/bin/bash

echo "Starting application initialization..."

# Wait for database
echo "Waiting for database connection..."
until php artisan migrate:status > /dev/null 2>&1; do
  echo "Database not ready, waiting..."
  sleep 5
done

# Run migrations
echo "Running database migrations..."
php artisan migrate --force

echo "Starting web services..."
mkdir -p /run/php-fpm
php-fpm -D
/usr/sbin/httpd -D FOREGROUND