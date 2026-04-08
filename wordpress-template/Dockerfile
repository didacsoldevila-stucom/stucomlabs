FROM wordpress:php8.3-apache

# PHP config
COPY php/99-custom.ini /usr/local/etc/php/conf.d/99-custom.ini

# MU plugin
COPY mu-plugins/smtp.php /var/www/html/wp-content/mu-plugins/smtp.php

# Permisos correctos
RUN chown -R www-data:www-data /var/www/html/wp-content