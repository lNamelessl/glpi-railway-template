#!/bin/bash
set -e

# Executed by the MariaDB entrypoint during first initialization, after
# MYSQL_DATABASE/MYSQL_USER are created. NOTE: with
# MARIADB_RANDOM_ROOT_PASSWORD=yes the entrypoint has already set the root
# password by this point, so connect using the generated one (exported in
# MARIADB_ROOT_PASSWORD / MYSQL_ROOT_PASSWORD).
ROOTPW="${MARIADB_ROOT_PASSWORD:-${MYSQL_ROOT_PASSWORD:-}}"
CLIENT="mariadb --protocol=socket -uroot"
if [ -n "$ROOTPW" ]; then
    CLIENT="mariadb --protocol=socket -uroot -p$ROOTPW"
fi

echo "Loading timezone tables from /usr/share/zoneinfo..."
mariadb-tzinfo-to-sql /usr/share/zoneinfo | $CLIENT mysql

echo "Granting SELECT on mysql.time_zone_name to '${MYSQL_USER}'@'%'..."
$CLIENT -e "GRANT SELECT ON mysql.time_zone_name TO \`${MYSQL_USER}\`@\`%\`; FLUSH PRIVILEGES;"

echo "Timezone tables loaded and grant applied."
