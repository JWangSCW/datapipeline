#!/bin/bash

# create Admin user, you can read these values from env or anywhere else possible
superset fab create-admin --username "$ADMIN_USERNAME" --firstname Superset --lastname Admin --email "$ADMIN_EMAIL" --password "$ADMIN_PASSWORD"

# Upgrading Superset metastore
superset db upgrade

# setup roles and permissions
superset superset init 

# superset set_database_uri -d hive_connection -u hive://hive@hive-server:10000/default
superset import-datasources -p /database_export.zip
superset import-dashboards -p /dashboard_export.zip 

# Starting server
/bin/sh -c /usr/bin/run-server.sh
