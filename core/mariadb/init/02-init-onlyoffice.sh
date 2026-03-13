#!/bin/bash
echo "Initializing OnlyOffice database and user..."

mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" <<-EOSQL
    CREATE DATABASE IF NOT EXISTS \`${ONLYOFFICE_DB_NAME}\`;
    CREATE USER IF NOT EXISTS '${ONLYOFFICE_DB_USER}'@'%' IDENTIFIED BY '${ONLYOFFICE_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${ONLYOFFICE_DB_NAME}\`.* TO '${ONLYOFFICE_DB_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL

echo "OnlyOffice initialization complete."