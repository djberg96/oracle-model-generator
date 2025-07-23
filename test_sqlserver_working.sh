#!/bin/bash

echo "=== Working SQL Server Test ==="
echo

# Start SQL Server container
echo "🚀 Starting SQL Server container..."
sudo docker stop sqlserver-working-test > /dev/null 2>&1 || true
sudo docker rm sqlserver-working-test > /dev/null 2>&1 || true

CONTAINER_ID=$(sudo docker run -d \
    --name sqlserver-working-test \
    -e "ACCEPT_EULA=Y" \
    -e "SA_PASSWORD=TestPassword123!" \
    -e "MSSQL_PID=Express" \
    -p 1433:1433 \
    mcr.microsoft.com/mssql/server:2022-latest)

echo "⏳ Waiting 90 seconds for SQL Server to start..."
sleep 90

# Create test database and table
echo "🏗️ Creating test database and table..."
sudo docker exec sqlserver-working-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "TestPassword123!" -C -Q "
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'workingtest')
BEGIN
    CREATE DATABASE workingtest;
END
"

sudo docker exec sqlserver-working-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "TestPassword123!" -d workingtest -C -Q "
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'customers')
BEGIN
    CREATE TABLE customers (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(255) UNIQUE,
        phone VARCHAR(20),
        status VARCHAR(20) DEFAULT 'active',
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE()
    );

    INSERT INTO customers (name, email, phone, status) VALUES
    ('Alice Johnson', 'alice@example.com', '555-0101', 'active'),
    ('Bob Wilson', 'bob@example.com', '555-0102', 'inactive'),
    ('Carol Davis', 'carol@example.com', '555-0103', 'active');
END
"

echo "✅ Test database and table created successfully"

echo "🧪 Testing Oracle Model Generator with SQL Server..."

# Test model generation
echo "📝 Generating model for customers table..."
bin/omg \
    --type sqlserver \
    --server localhost \
    --port 1433 \
    --user sa \
    --password "TestPassword123!" \
    --database workingtest \
    --table customers \
    --output customer.rb

echo
if [ -f "customer.rb" ]; then
    echo "✅ Model generated successfully!"
    echo "📄 Generated customer.rb:"
    echo "--- Content ---"
    cat customer.rb
    echo "--- End ---"
    echo
else
    echo "❌ Model generation failed"
fi

echo "🔍 Testing index recommendations..."
bin/omg \
    --type sqlserver \
    --server localhost \
    --port 1433 \
    --user sa \
    --password "TestPassword123!" \
    --database workingtest \
    --table customers \
    --indexes

echo
echo "🧹 Cleaning up..."
sudo docker stop sqlserver-working-test > /dev/null 2>&1
sudo docker rm sqlserver-working-test > /dev/null 2>&1
rm -f customer.rb

echo "✅ Working test completed!"
