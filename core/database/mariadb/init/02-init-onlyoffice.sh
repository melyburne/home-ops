#!/bin/bash
echo "Initializing OnlyOffice database and user..."

export MYSQL_PWD="${MARIADB_ROOT_PASSWORD}"
mariadb -u root <<-EOSQL
    CREATE DATABASE IF NOT EXISTS \`${ONLYOFFICE_DB_NAME}\`;
    CREATE USER IF NOT EXISTS '${ONLYOFFICE_DB_USER}'@'%' IDENTIFIED BY '${ONLYOFFICE_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${ONLYOFFICE_DB_NAME}\`.* TO '${ONLYOFFICE_DB_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL

echo "OnlyOffice initialization complete."