#!/bin/bash

mkdir -p /run/php-fpm

php-fpm -D

/usr/sbin/httpd -D FOREGROUND