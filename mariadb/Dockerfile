# Railway template wrapper for MariaDB (GLPI 11 requires MariaDB >= 10.6).
# Bakes the upstream defaults so the marketplace deploy needs zero manual
# inputs. The glpi user's password is NOT set here — it comes from the shared
# MYSQL_PASSWORD expression variable (referenced by the glpi service).
FROM mariadb:10.11

ENV MARIADB_RANDOM_ROOT_PASSWORD=yes \
    MYSQL_DATABASE=glpi \
    MYSQL_USER=glpi \
    MARIADB_AUTO_UPGRADE=yes \
    TZ=UTC

# Loads the timezone tables and grants the glpi user SELECT on
# mysql.time_zone_name (required by GLPI's database:enable_timezones).
# Runs once, on first initialization of the data directory, after the
# glpi database + user have been created by the image entrypoint.
COPY 01-timezones.sh /docker-entrypoint-initdb.d/01-timezones.sh

CMD ["mariadbd", "--character-set-server=utf8mb4", "--collation-server=utf8mb4_unicode_ci", "--innodb-file-per-table=1"]
