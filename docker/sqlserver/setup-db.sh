#!/bin/bash

# Wait for SQL Server to start
sleep 30s

# Run the initialization script
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -d master -i /opt/mssql-tools/scripts/init-db.sql

echo "Database initialization completed"
