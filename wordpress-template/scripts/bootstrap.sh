#!/bin/sh
set -eu

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "== Esperando a WordPress files =="
until [ -f /var/www/html/wp-load.php ] || [ -f /var/www/html/wp-config-sample.php ]; do
  sleep 2
done

log "== Preparando MU-plugin SMTP =="
mkdir -p /var/www/html/wp-content/mu-plugins
cp /tmp/smtp.php /var/www/html/wp-content/mu-plugins/smtp.php

log "== Creando wp-config.php =="
if [ ! -f /var/www/html/wp-config.php ]; then
  wp config create \
    --dbname="${WORDPRESS_DB_NAME}" \
    --dbuser="${WORDPRESS_DB_USER}" \
    --dbpass="${WORDPRESS_DB_PASSWORD}" \
    --dbhost="${WORDPRESS_DB_HOST}" \
    --path=/var/www/html
fi

log "== Ajustando wp-config.php =="
wp config set FS_METHOD direct --type=constant --path=/var/www/html || true

log "== Esperando a base de datos =="
until php -r '
$host = getenv("WORDPRESS_DB_HOST");
$user = getenv("WORDPRESS_DB_USER");
$pass = getenv("WORDPRESS_DB_PASSWORD");
$db   = getenv("WORDPRESS_DB_NAME");

mysqli_report(MYSQLI_REPORT_OFF);
$mysqli = @new mysqli($host, $user, $pass, $db);

if ($mysqli->connect_errno) {
    exit(1);
}

$mysqli->close();
exit(0);
' >/dev/null 2>&1; do
  sleep 3
done

log "== Comprobando si WordPress ya está instalado =="
if wp core is-installed --path=/var/www/html >/dev/null 2>&1; then
  log "WordPress ya está instalado. Saliendo."
  exit 0
fi

log "== Instalando WordPress =="
TEMP_ADMIN_PASSWORD="$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 24)"

wp core install \
  --url="https://${DOMAIN}" \
  --title="${WP_TITLE}" \
  --admin_user="${SUPPORT_USER}" \
  --admin_password="${SUPPORT_PASSWORD}" \
  --admin_email="${SUPPORT_EMAIL}" \
  --skip-email \
  --locale=ca \
  --path=/var/www/html

log "== Instalando y activando idioma catalán =="
wp core language install ca --activate --path=/var/www/html || true
wp site switch-language ca --path=/var/www/html || true

log "== Ajustando indexación =="
wp option update blog_public 0 --path=/var/www/html

log "== Instalando Elementor free =="
wp plugin install elementor --activate --path=/var/www/html

# Descomenta estas líneas cuando ya tengas el ZIP y la licencia listos
# log "== Instalando Elementor Pro =="
# wp plugin install /plugins/elementor-pro.zip --activate --path=/var/www/html
#
# log "== Activando licencia de Elementor Pro =="
# wp elementor-pro license activate "${ELEMENTOR_PRO_LICENSE}" --path=/var/www/html

log "== Creando usuario alumno =="
wp user create "${STUDENT_CODE}" "${STUDENT_EMAIL}" \
  --role=administrator \
  --first_name="${STUDENT_NAME}" \
  --last_name="${STUDENT_SURNAME}" \
  --user_pass="${TEMP_ADMIN_PASSWORD}" \
  --path=/var/www/html

log "== Forzando reset de contraseña por email =="
wp eval "retrieve_password('${STUDENT_CODE}');" --path=/var/www/html

log "== Bootstrap completado =="