#!/bin/bash

echo "=== Oracle Model Generator Test ==="
echo

# Check if Docker is available
if ! docker --version > /dev/null 2>&1; then
    echo "❌ Docker is not available"
    exit 1
fi

echo "✅ Docker is available"

# Start Oracle database
echo "🚀 Starting Oracle database with Docker Compose..."
docker-compose up -d

echo "⏳ Waiting for Oracle to be ready..."
# Wait for Oracle to be healthy
timeout=300
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose logs oracle-db 2>/dev/null | grep -q "DATABASE IS READY TO USE"; then
        echo "✅ Oracle database is ready"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    echo "   Still waiting... (${elapsed}s/${timeout}s)"
done

if [ $elapsed -ge $timeout ]; then
    echo "❌ Oracle database failed to start within ${timeout} seconds"
    docker-compose logs oracle-db
    exit 1
fi

echo "🧪 Oracle database is ready for testing"
echo "📋 You can now run Oracle Model Generator tests"
echo
echo "To stop the database:"
echo "  docker-compose down"
echo
echo "To connect to Oracle:"
echo "  docker-compose exec oracle-db sqlplus hr/oracle@//localhost:1521/XEPDB1"
