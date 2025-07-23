#!/bin/bash

echo "=== Quick SQL Server Model Test ==="

# Clean up and start fresh container
sudo docker stop test-sqlserver-debug > /dev/null 2>&1 || true
sudo docker rm test-sqlserver-debug > /dev/null 2>&1 || true

sudo docker run -d --name test-sqlserver-debug \
    -e "ACCEPT_EULA=Y" \
    -e "SA_PASSWORD=TestPassword123!" \
    -e "MSSQL_PID=Express" \
    -p 1433:1433 \
    mcr.microsoft.com/mssql/server:2022-latest

echo "⏳ Waiting 60 seconds for SQL Server to start..."
sleep 60

# Create database and table
sudo docker exec test-sqlserver-debug /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "TestPassword123!" -C -Q "
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'quicktest')
BEGIN
    CREATE DATABASE quicktest;
END
"

sleep 5

sudo docker exec test-sqlserver-debug /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "TestPassword123!" -d quicktest -C -Q "
CREATE TABLE customers (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    status VARCHAR(20) DEFAULT 'active'
);
INSERT INTO customers (name, email) VALUES ('Test User', 'test@example.com');
"

echo "✅ Database and table created"

# Test model generation
echo "🧪 Testing model generation..."
timeout 30s bin/omg \
    --type sqlserver \
    --server localhost \
    --port 1433 \
    --user sa \
    --password "TestPassword123!" \
    --database quicktest \
    --table customers \
    --output customer_test.rb

if [ -f "customer_test.rb" ]; then
    echo "✅ Model generated successfully!"
    echo "📄 Generated model:"
    cat customer_test.rb
else
    echo "❌ Model generation failed"
fi

# Clean up
sudo docker stop test-sqlserver-debug
sudo docker rm test-sqlserver-debug
rm -f customer_test.rb

echo "✅ Test completed!"
