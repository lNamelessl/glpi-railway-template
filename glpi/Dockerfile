# Railway template wrapper for the official GLPI image (pinned release).
# Why a wrapper exists:
#   1. Railway mounts volumes as root:root, but the glpi/glpi image runs as
#      USER www-data and its entrypoint aborts when /var/glpi is not writable.
#      This wrapper chowns the volume, then drops back to www-data via setpriv.
#   2. It bakes the literal GLPI_DB_* defaults (name/user/port) into the image
#      so the marketplace deploy needs zero manual inputs — host and password
#      are wired per-deploy by Railway expressions (never hardcoded).
#   3. It adds a static /healthz file (served by Apache, no PHP) for the
#      Railway healthcheck, and enables MySQL timezone tables after install.
FROM glpi/glpi:11.0.9

USER root

COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
COPY postinstall.sh /usr/local/bin/railway-postinstall.sh

RUN chmod +x /usr/local/bin/railway-entrypoint.sh /usr/local/bin/railway-postinstall.sh \
    && printf 'ok' > /var/www/glpi/public/healthz \
    && mkdir -p /var/glpi && chown www-data:www-data /var/glpi

# Literal DB config baked as image defaults (service vars override these).
# GLPI_DB_HOST and GLPI_DB_PASSWORD are intentionally NOT set here — they are
# provided per-deploy via ${{mariadb.RAILWAY_PRIVATE_DOMAIN}} and
# ${{mariadb.MYSQL_PASSWORD}} so credentials stay out of the image.
ENV GLPI_DB_PORT=3306 \
    GLPI_DB_NAME=glpi \
    GLPI_DB_USER=glpi \
    PORT=80

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
