#!/bin/bash
set -e -u -o pipefail

# Runs once per boot as www-data, after the upstream entrypoint has finished
# its auto-install / auto-update step (it is exec'd in place of supervisord).
# Enables the MySQL/MariaDB timezone tables for GLPI. Requires SELECT on
# mysql.time_zone_name, which the mariadb service's init script grants.
# Idempotent: safe on every boot; a failure never blocks startup.
cd /var/www/glpi

if [ -f "${GLPI_CONFIG_DIR:-/var/glpi/config}/config_db.php" ]; then
    echo "[railway] Enabling GLPI timezone tables..."
    if php bin/console database:enable_timezones --no-interaction; then
        echo "[railway] Timezone tables enabled."
    else
        echo "[railway] WARNING: database:enable_timezones failed (continuing; run it manually via 'railway ssh')."
    fi
fi

exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
