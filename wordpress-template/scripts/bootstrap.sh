#!/bin/sh
set -eu

echo "== Esperando a WordPress files =="
until [ -f /var/www/html/wp-load.php ] || [ -f /var/www/html/wp-config-sample.php ]; do
  sleep 2
done

echo "== Esperando a base de datos =="
until wp db check --path=/var/www/html >/dev/null 2>&1; do
  sleep 3
done

echo "== Comprobando si WordPress ya está instalado =="
if wp core is-installed --path=/var/www/html >/dev/null 2>&1; then
  echo "WordPress ya está instalado. Saliendo."
  exit 0
fi

echo "== Instalando WordPress =="
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

echo "== Ajustando idioma e indexación =="
wp option update blog_public 0 --path=/var/www/html

echo "== Instalando Elementor free =="
wp plugin install elementor --activate --path=/var/www/html

echo "== Instalando Elementor Pro =="
# wp plugin install /plugins/elementor-pro.zip --activate --path=/var/www/html

echo "== Activando licencia de Elementor Pro =="
# wp elementor-pro license activate "${ELEMENTOR_PRO_LICENSE}" --path=/var/www/html

echo "== Creando usuario alumno =="
wp user create "${STUDENT_CODE}" "${STUDENT_EMAIL}" \
  --role=administrator \
  --first_name="${STUDENT_NAME}" \
  --last_name="${STUDENT_SURNAME}" \
  --user_pass="${TEMP_ADMIN_PASSWORD}" \
  --path=/var/www/html

echo "== Forzando reset de contraseña por email =="
wp eval "retrieve_password('${STUDENT_CODE}');" --path=/var/www/html

echo "== Bootstrap completado =="