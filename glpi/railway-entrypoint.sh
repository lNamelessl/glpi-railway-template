#!/bin/bash
set -e -u -o pipefail

# Railway mounts volumes as root:root. The upstream glpi/glpi entrypoint runs
# as www-data and exits 1 when /var/glpi is not writable, so fix ownership
# first, then drop privileges and hand off to the upstream entrypoint.
if [ -d /var/glpi ]; then
    chown -R www-data:www-data /var/glpi
fi

# Railway's runtime has been observed to leave more than one Apache MPM
# enabled in php:apache-based images (AH00534 "More than one MPM loaded").
# mod_php needs prefork — force exactly one MPM. Idempotent.
if command -v a2dismod >/dev/null 2>&1; then
    a2dismod --quiet mpm_event >/dev/null 2>&1 || true
    a2dismod --quiet mpm_worker >/dev/null 2>&1 || true
    a2enmod --quiet mpm_prefork >/dev/null 2>&1 || true
fi

WUID="$(id -u www-data)"
WGID="$(id -g www-data)"

exec setpriv --reuid="$WUID" --regid="$WGID" --init-groups \
    /opt/glpi/entrypoint.sh /usr/local/bin/railway-postinstall.sh
