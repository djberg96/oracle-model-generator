# Docker Support for Database Model Generator

This directory contains Docker configurations for testing the Database Model Generator with different database systems.

## Directory Structure

- `oracle/` - Oracle database Docker configurations and documentation
- `sqlserver/` - SQL Server database Docker configurations and documentation

## Quick Start

### Oracle
```bash
cd oracle
docker-compose up
```

### SQL Server
```bash
cd sqlserver
docker-compose up
```

## Database-Specific Documentation

- [Oracle Docker Setup](oracle/README.md)
- [SQL Server Docker Setup](sqlserver/DOCKER.md)
- [SQL Server Testing Guide](sqlserver/TESTING.md)
- [SQL Server Support Documentation](sqlserver/SUPPORT.md)

## Requirements

- Docker
- Docker Compose
- Ruby 3.0+ (for local development)

## Testing

Each database type includes its own testing scripts and documentation. See the individual directories for specific instructions.

## Quick Start

### Option 1: Simple Test (Recommended)

Run the simple test script that handles everything automatically:

```bash
./test_sqlserver_simple.sh
```

This script will:
- Start a SQL Server container
- Create a test database with sample tables
- Test the Database Model Generator
- Show generated models and tests
- Clean up when done

### Option 2: Docker Compose (Advanced)

Use Docker Compose for more control:

```bash
# Start SQL Server
docker-compose -f docker-compose.sqlserver.yml up -d sqlserver

# Wait for SQL Server to be ready (1-2 minutes)
# Then run tests
docker-compose -f docker-compose.sqlserver.yml up omg_test

# Clean up
docker-compose -f docker-compose.sqlserver.yml down -v
```

### Option 3: Manual Docker Setup

```bash
# Start SQL Server container
docker run -d \
  --name sqlserver_test \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=YourStrong!Passw0rd" \
  -e "MSSQL_PID=Express" \
  -p 1433:1433 \
  mcr.microsoft.com/mssql/server:2022-latest

# Wait for startup (about 1 minute)
sleep 60

# Create test database
docker exec sqlserver_test /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P YourStrong!Passw0rd \
  -Q "CREATE DATABASE test_db"

# Test the generator
ruby bin/omg -T sqlserver -s localhost -P 1433 -d test_db \
  -u sa -p 'YourStrong!Passw0rd' -t INFORMATION_SCHEMA.TABLES -x rspec

# Clean up
docker stop sqlserver_test && docker rm sqlserver_test
```

## Database Schema

The test setup creates a sample database with the following tables:

### users
- id (INT, PRIMARY KEY, IDENTITY)
- username (NVARCHAR(50), UNIQUE)
- email (NVARCHAR(100), UNIQUE)
- first_name, last_name (NVARCHAR(50))
- age (INT)
- salary (DECIMAL(10,2))
- is_active (BIT)
- status (NVARCHAR(20))
- created_at, updated_at (DATETIME2)
- bio (NVARCHAR(MAX))

### posts
- id (INT, PRIMARY KEY, IDENTITY)
- user_id (INT, FOREIGN KEY → users.id)
- title (NVARCHAR(200))
- content (NVARCHAR(MAX))
- status (NVARCHAR(20))
- published_at (DATETIME2)
- created_at (DATETIME2)
- view_count (INT)

### categories
- id (INT, PRIMARY KEY, IDENTITY)
- name (NVARCHAR(100), UNIQUE)
- description (NVARCHAR(500))
- slug (NVARCHAR(100), UNIQUE)
- parent_id (INT, FOREIGN KEY → categories.id)
- is_active (BIT)
- created_at (DATETIME2)

### post_categories (Junction table)
- id (INT, PRIMARY KEY, IDENTITY)
- post_id (INT, FOREIGN KEY → posts.id)
- category_id (INT, FOREIGN KEY → categories.id)
- created_at (DATETIME2)

### comments
- id (INT, PRIMARY KEY, IDENTITY)
- post_id (INT, FOREIGN KEY → posts.id)
- user_id (INT, FOREIGN KEY → users.id)
- content (NVARCHAR(MAX))
- status (NVARCHAR(20))
- created_at, updated_at (DATETIME2)

## Connection Details

When testing manually:
- **Server**: localhost:1433
- **Username**: sa
- **Password**: YourStrong!Passw0rd
- **Database**: test_db

## Prerequisites

- Docker installed and running
- Ruby with bundler
- `tiny_tds` gem (automatically installed by test scripts)

### Installing tiny_tds

If you need to install the `tiny_tds` gem manually:

**Ubuntu/Debian:**
```bash
sudo apt-get install build-essential freetds-dev
gem install tiny_tds
```

**macOS:**
```bash
brew install freetds
gem install tiny_tds
```

**Windows:**
```bash
gem install tiny_tds
```

## Test Features

The test scripts verify:

1. **Model Generation**: Creates ActiveRecord models from SQL Server tables
2. **Test Generation**: Creates RSpec, Minitest, or TestUnit test files
3. **Index Recommendations**: Analyzes tables and suggests performance indexes
4. **Auto-detection**: Automatically detects SQL Server when server parameter is provided
5. **Foreign Key Relationships**: Maps foreign keys to ActiveRecord associations
6. **Data Type Mapping**: Correctly maps SQL Server types to Ruby/Rails validations

## Example Usage

```bash
# Generate a User model with RSpec tests
ruby bin/omg -T sqlserver -s localhost -P 1433 -d test_db \
  -u sa -p 'YourStrong!Passw0rd' -t users -x rspec

# Show index recommendations for posts table
ruby bin/omg -T sqlserver -s localhost -P 1433 -d test_db \
  -u sa -p 'YourStrong!Passw0rd' -t posts -i

# Auto-detect database type (SQL Server)
ruby bin/omg -s localhost -d test_db -u sa -p 'YourStrong!Passw0rd' -t categories
```

## Troubleshooting

### SQL Server not starting
- Wait longer (SQL Server can take 2-3 minutes to fully start)
- Check Docker logs: `docker logs sqlserver_test`
- Ensure port 1433 is not in use

### Connection errors
- Verify the password meets SQL Server requirements (8+ chars, mixed case, numbers, symbols)
- Check firewall settings
- Ensure SQL Server container is fully started

### tiny_tds installation issues
- Install system dependencies (freetds-dev on Linux, freetds on macOS)
- Check Ruby version compatibility
- Try using the system package manager version

## Files

- `docker/sqlserver/Dockerfile` - SQL Server container setup
- `docker/sqlserver/init-db.sql` - Database initialization script
- `docker/sqlserver/setup-db.sh` - Database setup automation
- `docker/test/Dockerfile` - Test runner container
- `docker/test/run_tests.sh` - Comprehensive test suite
- `docker-compose.sqlserver.yml` - Docker Compose configuration
- `test_sqlserver_simple.sh` - Simple all-in-one test script
- `test_sqlserver_docker.sh` - Advanced Docker test script
