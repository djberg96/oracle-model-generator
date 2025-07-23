#!/bin/bash

echo "=== Quick SQL Server Test ==="
echo

# Start SQL Server container
echo "🚀 Starting SQL Server container..."
CONTAINER_ID=$(sudo docker run -d \
    --name sqlserver-quick-test \
    -e "ACCEPT_EULA=Y" \
    -e "SA_PASSWORD=TestPassword123!" \
    -e "MSSQL_PID=Express" \
    -p 1433:1433 \
    mcr.microsoft.com/mssql/server:2022-latest)

echo "⏳ Waiting 90 seconds for SQL Server to start..."
sleep 90

# Create a simple test table
echo "🏗️ Creating test table..."
sudo docker exec sqlserver-quick-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "TestPassword123!" -C -Q "
CREATE DATABASE quicktest;
USE quicktest;
CREATE TABLE employees (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE DEFAULT GETDATE()
);
INSERT INTO employees (name, email, department, salary) VALUES
('John Doe', 'john@company.com', 'Engineering', 75000.00),
('Jane Smith', 'jane@company.com', 'Marketing', 65000.00);
"

echo "🧪 Testing Oracle Model Generator with SQL Server..."

# Test model generation for employees table
echo "📝 Generating model for employees table..."
timeout 30s bin/omg \
    --database sqlserver \
    --host localhost \
    --port 1433 \
    --username sa \
    --password "TestPassword123!" \
    --database-name quicktest \
    --table employees \
    --output employee.rb \
    --trust-server-certificate

echo
if [ -f "employee.rb" ]; then
    echo "✅ Model generated successfully!"
    echo "📄 Generated employee.rb:"
    echo "--- Content ---"
    cat employee.rb
    echo "--- End ---"
else
    echo "❌ Model generation failed"
fi

echo
echo "🔍 Testing index recommendations..."
timeout 30s bin/omg \
    --database sqlserver \
    --host localhost \
    --port 1433 \
    --username sa \
    --password "TestPassword123!" \
    --database-name quicktest \
    --table employees \
    --indexes \
    --trust-server-certificate

echo
echo "🧹 Cleaning up..."
sudo docker stop sqlserver-quick-test > /dev/null 2>&1
sudo docker rm sqlserver-quick-test > /dev/null 2>&1
rm -f employee.rb

echo "✅ Quick test completed!"
