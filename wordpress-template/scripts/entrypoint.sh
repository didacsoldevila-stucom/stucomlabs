#!/bin/sh
set -eu

mkdir -p /run/secrets
chmod 755 /run/secrets

write_secret() {
  var_name="$1"
  file_path="$2"

  value="$(printenv "$var_name" 2>/dev/null || true)"
  if [ -n "$value" ]; then
    printf '%s' "$value" > "$file_path"
    chown www-data:www-data "$file_path"
    chmod 600 "$file_path"
  fi
}

write_secret DB_PASSWORD /run/secrets/db_password
write_secret SMTP_USER /run/secrets/smtp_user
write_secret SMTP_PASS /run/secrets/smtp_pass

export WORDPRESS_DB_PASSWORD_FILE=/run/secrets/db_password

unset DB_PASSWORD
unset SMTP_USER
unset SMTP_PASS

mkdir -p /var/www/html/wp-content/mu-plugins

if [ -f /usr/src/stucom/mu-plugins/smtp.php ]; then
  cp /usr/src/stucom/mu-plugins/smtp.php /var/www/html/wp-content/mu-plugins/smtp.php
  chown www-data:www-data /var/www/html/wp-content/mu-plugins/smtp.php
  chmod 0644 /var/www/html/wp-content/mu-plugins/smtp.php
fi

mkdir -p /var/www/html/wp-content/uploads
chown www-data:www-data /var/www/html/wp-content/uploads

cat <<EOF > /var/www/html/wp-content/uploads/.htaccess
<FilesMatch "\.php$">
    Require all denied
</FilesMatch>
EOF

chown www-data:www-data /var/www/html/wp-content/uploads/.htaccess
chmod 644 /var/www/html/wp-content/uploads/.htaccess

exec docker-entrypoint.sh apache2-foreground