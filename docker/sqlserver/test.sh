#!/bin/bash

echo "=== SQL Server Model Generator Test ==="
echo

# Check if Docker is available
if ! docker --version > /dev/null 2>&1; then
    echo "❌ Docker is not available"
    exit 1
fi

echo "✅ Docker is available"

# Start SQL Server database
echo "🚀 Starting SQL Server database with Docker Compose..."
docker-compose up -d

echo "⏳ Waiting for SQL Server to be ready (90 seconds)..."
sleep 90

# Test connection
echo "🔍 Testing SQL Server connectivity..."
if docker-compose exec -T sqlserver-db /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "TestPassword123!" -C -Q "SELECT @@VERSION" > /dev/null 2>&1; then
    echo "✅ SQL Server is running and accessible"
else
    echo "❌ SQL Server connectivity test failed"
    echo "📋 Container logs:"
    docker-compose logs sqlserver-db | tail -20
    exit 1
fi

# Create test database if it doesn't exist
echo "🏗️ Setting up test database..."
docker-compose exec -T sqlserver-db /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "TestPassword123!" -C -Q "
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'testdb')
BEGIN
    CREATE DATABASE testdb;
END
"

echo "✅ SQL Server is ready for testing"
echo "📋 You can now run SQL Server Model Generator tests"
echo
echo "Connection details:"
echo "  Host: localhost"
echo "  Port: 1433"
echo "  Username: sa"
echo "  Password: TestPassword123!"
echo "  Database: testdb"
echo
echo "To stop the database:"
echo "  docker-compose down"
echo
echo "To test model generation:"
echo "  cd ../../"
echo "  bin/dmg --type sqlserver --server localhost --port 1433 --user sa --password TestPassword123! --database testdb --table <table_name>"
