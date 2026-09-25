#!/bin/bash
set -e -u -o pipefail

# Railway mounts volumes as root:root. The upstream glpi/glpi entrypoint runs
# as www-data and exits 1 when /var/glpi is not writable, so fix ownership
# first, then drop privileges and hand off to the upstream entrypoint.
if [ -d /var/glpi ]; then
    chown -R www-data:www-data /var/glpi
fi

WUID="$(id -u www-data)"
WGID="$(id -g www-data)"

exec setpriv --reuid="$WUID" --regid="$WGID" --init-groups \
    /opt/glpi/entrypoint.sh /usr/local/bin/railway-postinstall.sh
