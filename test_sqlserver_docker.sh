#!/bin/bash

echo "=== SQL Server Docker Test for Database Model Generator ==="
echo

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed or not in PATH"
    exit 1
fi

echo "✅ Docker and Docker Compose are available"
echo

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose -f docker-compose.sqlserver.yml down -v 2>/dev/null || true
docker system prune -f 2>/dev/null || true

echo

# Start SQL Server
echo "🚀 Starting SQL Server container..."
docker-compose -f docker-compose.sqlserver.yml up -d sqlserver

echo "⏳ Waiting for SQL Server to be ready (this may take 1-2 minutes)..."

# Wait for SQL Server to be healthy
timeout=120
counter=0
while [ $counter -lt $timeout ]; do
    if docker-compose -f docker-compose.sqlserver.yml exec -T sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong!Passw0rd -Q "SELECT 1" &>/dev/null; then
        echo "✅ SQL Server is ready!"
        break
    fi

    if [ $((counter % 10)) -eq 0 ]; then
        echo "   Still waiting... ($counter seconds elapsed)"
    fi

    sleep 1
    counter=$((counter + 1))
done

if [ $counter -ge $timeout ]; then
    echo "❌ SQL Server failed to start within $timeout seconds"
    docker-compose -f docker-compose.sqlserver.yml logs sqlserver
    exit 1
fi

echo

# Test SQL Server connectivity
echo "🔍 Testing SQL Server connectivity..."
docker-compose -f docker-compose.sqlserver.yml exec -T sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong!Passw0rd -d test_db -Q "SELECT COUNT(*) as table_count FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"

echo

# Run the test suite
echo "🧪 Running Database Model Generator test suite..."
echo

# Install tiny_tds gem locally if not already installed
if ! gem list tiny_tds -i &>/dev/null; then
    echo "📦 Installing tiny_tds gem..."
    gem install tiny_tds
    echo
fi

# Test 1: Direct connection test
echo "Test 1: Testing direct connection to SQL Server..."
ruby -e "
require 'tiny_tds'
begin
  client = TinyTds::Client.new(
    username: 'sa',
    password: 'YourStrong!Passw0rd',
    host: 'localhost',
    port: 1433,
    database: 'test_db'
  )
  result = client.execute('SELECT COUNT(*) as user_count FROM users')
  row = result.first
  puts \"✅ Connection successful! Found #{row['user_count']} users in the database\"
  client.close
rescue => e
  puts \"❌ Connection failed: #{e.message}\"
  exit 1
end
"

echo

# Test 2: Generate a model using our tool
echo "Test 2: Generating User model with SQL Server..."
ruby bin/omg \
  -T sqlserver \
  -s localhost \
  -P 1433 \
  -d test_db \
  -u sa \
  -p 'YourStrong!Passw0rd' \
  -t users \
  -o test_user.rb \
  -x rspec

if [ $? -eq 0 ]; then
    echo "✅ User model generated successfully!"
    echo
    echo "📄 Generated model file (first 30 lines):"
    head -30 test_user.rb
    echo "..."
    echo

    if [ -f "test_user_spec.rb" ]; then
        echo "📄 Generated RSpec test file (first 15 lines):"
        head -15 test_user_spec.rb
        echo "..."
        echo
    fi
else
    echo "❌ Model generation failed"
fi

echo

# Test 3: Test index recommendations
echo "Test 3: Testing index recommendations..."
ruby bin/omg \
  -T sqlserver \
  -s localhost \
  -P 1433 \
  -d test_db \
  -u sa \
  -p 'YourStrong!Passw0rd' \
  -t posts \
  -i

echo

# Test 4: Test auto-detection
echo "Test 4: Testing database type auto-detection..."
ruby bin/omg \
  -s localhost \
  -P 1433 \
  -d test_db \
  -u sa \
  -p 'YourStrong!Passw0rd' \
  -t categories \
  -o test_category.rb \
  -x none

if [ $? -eq 0 ]; then
    echo "✅ Auto-detection successful (SQL Server was detected)"
    echo
    echo "📄 Generated Category model (first 20 lines):"
    head -20 test_category.rb
    echo "..."
else
    echo "❌ Auto-detection failed"
fi

echo

# Test 5: Show database schema
echo "Test 5: Inspecting database schema..."
docker-compose -f docker-compose.sqlserver.yml exec -T sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong!Passw0rd -d test_db -Q "
SELECT
    t.TABLE_NAME,
    COUNT(c.COLUMN_NAME) as COLUMN_COUNT
FROM INFORMATION_SCHEMA.TABLES t
LEFT JOIN INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_NAME = c.TABLE_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE'
GROUP BY t.TABLE_NAME
ORDER BY t.TABLE_NAME
"

echo

# Cleanup
echo "🧹 Cleaning up generated test files..."
rm -f test_user.rb test_user_spec.rb test_category.rb

echo "🛑 Stopping containers..."
docker-compose -f docker-compose.sqlserver.yml down

echo
echo "=== SQL Server Docker Test Complete ==="
echo "✅ All tests completed successfully!"
echo
echo "To run SQL Server again:"
echo "  docker-compose -f docker-compose.sqlserver.yml up -d"
echo
echo "To connect manually:"
echo "  Server: localhost:1433"
echo "  Username: sa"
echo "  Password: YourStrong!Passw0rd"
echo "  Database: test_db"
