#!/bin/bash
echo "Initializing Home Assistant database and user..."

export MYSQL_PWD="${MARIADB_ROOT_PASSWORD}"
mariadb -u root <<-EOSQL
    CREATE DATABASE IF NOT EXISTS \`${HOMEASSISTANT_DB_NAME}\`;
    CREATE USER IF NOT EXISTS '${HOMEASSISTANT_DB_USER}'@'%' IDENTIFIED BY '${HOMEASSISTANT_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${HOMEASSISTANT_DB_NAME}\`.* TO '${HOMEASSISTANT_DB_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL

echo "Home Assistant initialization complete."