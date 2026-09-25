#!/bin/bash
set -e

# Executed by the MariaDB entrypoint during first initialization, connected
# as root over the unix socket, after MYSQL_DATABASE/MYSQL_USER are created.

echo "Loading timezone tables from /usr/share/zoneinfo..."
mariadb-tzinfo-to-sql /usr/share/zoneinfo | mariadb --protocol=socket -uroot mysql

echo "Granting SELECT on mysql.time_zone_name to '${MYSQL_USER}'@'%'..."
mariadb --protocol=socket -uroot -e "GRANT SELECT ON mysql.time_zone_name TO \`${MYSQL_USER}\`@\`%\`; FLUSH PRIVILEGES;"

echo "Timezone tables loaded and grant applied."
