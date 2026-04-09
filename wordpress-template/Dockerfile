FROM wordpress:php8.3-apache

COPY php/99-custom.ini /usr/local/etc/php/conf.d/99-custom.ini
COPY mu-plugins/smtp.php /usr/src/stucom/mu-plugins/smtp.php
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]