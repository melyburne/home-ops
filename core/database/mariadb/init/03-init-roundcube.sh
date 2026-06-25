#!/bin/bash
echo "Initializing Roundcube database and user..."

export MYSQL_PWD="${MARIADB_ROOT_PASSWORD}"
mariadb -u root <<-EOSQL
    CREATE DATABASE IF NOT EXISTS \`${ROUNDCUBE_DB_NAME}\`;
    CREATE USER IF NOT EXISTS '${ROUNDCUBE_DB_USER}'@'%' IDENTIFIED BY '${ROUNDCUBE_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${ROUNDCUBE_DB_NAME}\`.* TO '${ROUNDCUBE_DB_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL

echo "Roundcube initialization complete."