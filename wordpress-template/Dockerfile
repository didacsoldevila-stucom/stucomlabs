FROM wordpress:php8.3-apache

COPY php/99-custom.ini /usr/local/etc/php/conf.d/99-custom.ini
COPY mu-plugins/smtp.php /usr/src/stucom/mu-plugins/smtp.php
COPY docker/entrypoint.sh /usr/local/bin/stucom-entrypoint.sh

RUN chmod +x /usr/local/bin/stucom-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/stucom-entrypoint.sh"]
CMD ["apache2-foreground"]