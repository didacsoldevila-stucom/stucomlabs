#!/bin/sh
set -eu

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

SECRETS_DIR="/tmp/stucom-secrets"
ELEMENTOR_PRO_ZIP_PATH="${ELEMENTOR_PRO_ZIP_PATH}"

write_secret() {
  var_name="$1"
  file_path="$2"

  value="$(printenv "$var_name" 2>/dev/null || true)"
  if [ -n "$value" ]; then
    mkdir -p "$(dirname "$file_path")"
    printf '%s' "$value" > "$file_path"
    chmod 600 "$file_path"
  fi
}

DB_PASSWORD="${DB_PASSWORD:-}"

write_secret DB_PASSWORD "${SECRETS_DIR}/db_password"
write_secret SMTP_USER "${SECRETS_DIR}/smtp_user"
write_secret SMTP_PASS "${SECRETS_DIR}/smtp_pass"

if [ -z "$DB_PASSWORD" ] && [ -f "${SECRETS_DIR}/db_password" ]; then
  DB_PASSWORD="$(cat "${SECRETS_DIR}/db_password")"
fi

if [ -z "$DB_PASSWORD" ] && [ -f /run/secrets/db_password ]; then
  DB_PASSWORD="$(cat /run/secrets/db_password)"
fi

if [ -z "$DB_PASSWORD" ]; then
  log "ERROR: No se ha proporcionado DB_PASSWORD"
  exit 1
fi

export WORDPRESS_DB_PASSWORD="$DB_PASSWORD"

log "== Esperando a WordPress files =="
until [ -f /var/www/html/wp-includes/version.php ]; do
  sleep 2
done

log "== Esperando a base de datos =="
until php -r '
  $host = getenv("WORDPRESS_DB_HOST");
  $user = getenv("WORDPRESS_DB_USER");
  $pass = getenv("WORDPRESS_DB_PASSWORD");
  $db   = getenv("WORDPRESS_DB_NAME");
  mysqli_report(MYSQLI_REPORT_OFF);
  $mysqli = @new mysqli($host, $user, $pass, $db);
  if ($mysqli->connect_errno) { exit(1); }
  $mysqli->close();
  exit(0);
' >/dev/null 2>&1; do
  sleep 3
done

log "== Creando wp-config.php =="
if [ ! -f /var/www/html/wp-config.php ]; then
  wp config create \
    --dbname="${WORDPRESS_DB_NAME}" \
    --dbuser="${WORDPRESS_DB_USER}" \
    --dbpass="${WORDPRESS_DB_PASSWORD}" \
    --dbhost="${WORDPRESS_DB_HOST}" \
    --path=/var/www/html \
    --skip-check
fi

log "== Ajustando wp-config.php =="
wp config set FS_METHOD direct --type=constant --path=/var/www/html || true
wp config set FORCE_SSL_ADMIN true --raw --type=constant --path=/var/www/html || true
wp config set DISALLOW_FILE_EDIT true --raw --type=constant --path=/var/www/html || true

WORDPRESS_ALREADY_INSTALLED="false"

log "== Comprobando si WordPress ya está instalado =="
if wp core is-installed --path=/var/www/html >/dev/null 2>&1; then
  WORDPRESS_ALREADY_INSTALLED="true"
  log "WordPress ya está instalado."
fi

if [ "$WORDPRESS_ALREADY_INSTALLED" = "false" ]; then

  log "== Instalando WordPress =="
  wp core install \
    --url="https://${DOMAIN}" \
    --title="${WP_TITLE}" \
    --admin_user="${STUDENT_CODE}" \
    --admin_password="${TEMP_ADMIN_PASSWORD}" \
    --admin_email="${STUDENT_EMAIL}" \
    --skip-email \
    --locale=ca \
    --path=/var/www/html

  log "== Instalando y activando idioma catalán =="
  wp core language install ca --activate --path=/var/www/html || true
  wp site switch-language ca --path=/var/www/html || true

  log "== Ajustando indexación =="
  wp option update blog_public 0 --path=/var/www/html

  log "== Configurando timezone =="
  wp option update timezone_string "Europe/Madrid" --path=/var/www/html

  log "== Instalando Elementor free =="
  wp plugin install elementor --activate --path=/var/www/html

  if [ -f "${ELEMENTOR_PRO_ZIP_PATH}" ]; then
    log "== Instalando Elementor Pro desde ZIP local =="
    wp plugin install "${ELEMENTOR_PRO_ZIP_PATH}" --activate --path=/var/www/html
  elif [ -n "${ELEMENTOR_PRO_URL:-}" ]; then
    log "== ZIP local no encontrado, instalando Elementor Pro desde URL =="
    wp plugin install "${ELEMENTOR_PRO_URL}" --activate --path=/var/www/html
  else
    log "== No se ha proporcionado ZIP local ni ELEMENTOR_PRO_URL, se omite Elementor Pro =="
  fi
else
  log "== Saltando instalación inicial de WordPress y plugins =="
fi

log "== Ajustando nombre y apellidos del alumno =="
wp user update "${STUDENT_CODE}" \
  --first_name="${STUDENT_NAME}" \
  --last_name="${STUDENT_SURNAME}" \
  --role=administrator \
  --path=/var/www/html

# En el despliegue inicial NO enviamos reset automáticamente.
# Solo lo enviamos cuando PASSWORD_RESET_TRIGGER tenga valor y cambie.
PASSWORD_RESET_TRIGGER="${PASSWORD_RESET_TRIGGER:-}"

if [ -n "$PASSWORD_RESET_TRIGGER" ]; then
  log "== Comprobando trigger de reset de contraseña =="

  LAST_TRIGGER="$(wp option get stucom_password_reset_trigger --path=/var/www/html 2>/dev/null || true)"

  if [ "$LAST_TRIGGER" != "$PASSWORD_RESET_TRIGGER" ]; then
    log "== Enviando correo de reset de contraseña =="
    wp eval "retrieve_password('${STUDENT_CODE}');" --path=/var/www/html
    wp option update stucom_password_reset_trigger "$PASSWORD_RESET_TRIGGER" --path=/var/www/html
  else
    log "== Trigger de reset ya procesado, no se reenvía =="
  fi
else
  log "== No se ha definido PASSWORD_RESET_TRIGGER, no se envía reset =="
fi

log "== Bootstrap completado =="