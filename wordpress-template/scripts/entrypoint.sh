#!/bin/sh
set -eu

mkdir -p /run/secrets
chmod 700 /run/secrets

write_secret() {
  var_name="$1"
  file_path="$2"

  value="$(printenv "$var_name" 2>/dev/null || true)"
  if [ -n "$value" ]; then
    printf '%s' "$value" > "$file_path"
    chmod 600 "$file_path"
  fi
}

write_secret DB_PASSWORD /run/secrets/db_password
write_secret SMTP_USER /run/secrets/smtp_user
write_secret SMTP_PASS /run/secrets/smtp_pass

mkdir -p /var/www/html/wp-content/mu-plugins
cp /usr/src/stucom/mu-plugins/smtp.php /var/www/html/wp-content/mu-plugins/smtp.php
chown www-data:www-data /var/www/html/wp-content/mu-plugins/smtp.php
chmod 0644 /var/www/html/wp-content/mu-plugins/smtp.php

exec docker-entrypoint.sh apache2-foreground