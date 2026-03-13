#!/bin/bash
echo "Initializing Roundcube database and user..."

mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" <<-EOSQL
    CREATE DATABASE IF NOT EXISTS \`${ROUNDCUBE_DB_NAME}\`;
    CREATE USER IF NOT EXISTS '${ROUNDCUBE_DB_USER}'@'%' IDENTIFIED BY '${ROUNDCUBE_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${ROUNDCUBE_DB_NAME}\`.* TO '${ROUNDCUBE_DB_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL

echo "Roundcube initialization complete."