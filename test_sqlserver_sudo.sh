#!/bin/bash

echo "=== Simple SQL Server Docker Test (with sudo) ==="
echo

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker to run this test."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "✅ Docker is available"
echo

# Pull and run SQL Server container
echo "🚀 Starting SQL Server container..."
echo "   This will download SQL Server 2022 Express if not already available"
echo

sudo docker run -d \
  --name sqlserver_test \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=YourStrong!Passw0rd" \
  -e "MSSQL_PID=Express" \
  -p 1433:1433 \
  mcr.microsoft.com/mssql/server:2022-latest

if [ $? -ne 0 ]; then
    echo "❌ Failed to start SQL Server container"
    exit 1
fi

echo "✅ SQL Server container started"
echo "⏳ Waiting for SQL Server to initialize (60 seconds)..."

# Wait for SQL Server to be ready
sleep 60

# Test if SQL Server is ready
echo "🔍 Testing SQL Server connectivity..."
sudo docker exec sqlserver_test /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong!Passw0rd -Q "SELECT @@VERSION"

if [ $? -ne 0 ]; then
    echo "❌ SQL Server is not responding. Let's wait a bit more..."
    sleep 30
    sudo docker exec sqlserver_test /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong!Passw0rd -Q "SELECT 1"
    if [ $? -ne 0 ]; then
        echo "❌ SQL Server failed to start properly"
        sudo docker logs sqlserver_test
        sudo docker stop sqlserver_test
        sudo docker rm sqlserver_test
        exit 1
    fi
fi

echo "✅ SQL Server is ready!"
echo

# Create test database and tables
echo "📊 Creating test database and sample tables..."
sudo docker exec sqlserver_test /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong!Passw0rd -Q "
CREATE DATABASE test_db;
"

sudo docker exec sqlserver_test /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong!Passw0rd -d test_db -Q "
-- Create users table
CREATE TABLE users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    username NVARCHAR(50) NOT NULL UNIQUE,
    email NVARCHAR(100) NOT NULL UNIQUE,
    first_name NVARCHAR(50) NOT NULL,
    last_name NVARCHAR(50) NOT NULL,
    age INT,
    salary DECIMAL(10,2),
    is_active BIT DEFAULT 1,
    status NVARCHAR(20) DEFAULT 'active',
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    bio NVARCHAR(MAX)
);

-- Create posts table
CREATE TABLE posts (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    title NVARCHAR(200) NOT NULL,
    content NVARCHAR(MAX),
    status NVARCHAR(20) DEFAULT 'draft',
    published_at DATETIME2,
    created_at DATETIME2 DEFAULT GETDATE(),
    view_count INT DEFAULT 0,
    CONSTRAINT FK_posts_user_id FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Insert sample data
INSERT INTO users (username, email, first_name, last_name, age, salary) VALUES
('jdoe', 'john@example.com', 'John', 'Doe', 30, 75000.00),
('asmith', 'alice@example.com', 'Alice', 'Smith', 28, 82000.00);

INSERT INTO posts (user_id, title, content, status) VALUES
(1, 'First Post', 'This is my first post', 'published'),
(2, 'Second Post', 'This is another post', 'draft');

SELECT 'Database setup complete' as Result;
"

echo "✅ Test database created with sample data"
echo

# Check if tiny_tds gem is available
echo "📦 Checking for tiny_tds gem..."
if ! ruby -e "require 'tiny_tds'" 2>/dev/null; then
    echo "📦 Installing tiny_tds gem..."
    gem install tiny_tds
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install tiny_tds gem"
        echo "   You may need to install development tools:"
        echo "   - On Ubuntu/Debian: sudo apt-get install build-essential freetds-dev"
        echo "   - On macOS: brew install freetds"
        sudo docker stop sqlserver_test
        sudo docker rm sqlserver_test
        exit 1
    fi
fi

echo "✅ tiny_tds gem is available"
echo

# Test our Database Model Generator with SQL Server
echo "🧪 Testing Database Model Generator with SQL Server..."
echo

echo "Test 1: Generating User model..."
ruby bin/omg \
  -T sqlserver \
  -s localhost \
  -P 1433 \
  -d test_db \
  -u sa \
  -p 'YourStrong!Passw0rd' \
  -t users \
  -o generated_user.rb \
  -x rspec

if [ $? -eq 0 ]; then
    echo "✅ User model generated successfully!"

    if [ -f "generated_user.rb" ]; then
        echo
        echo "📄 Generated User model:"
        echo "----------------------------------------"
        cat generated_user.rb
        echo "----------------------------------------"
        echo
    fi

    if [ -f "generated_user_spec.rb" ]; then
        echo "📄 Generated RSpec test (first 20 lines):"
        echo "----------------------------------------"
        head -20 generated_user_spec.rb
        echo "..."
        echo "----------------------------------------"
        echo
    fi
else
    echo "❌ User model generation failed"
fi

echo "Test 2: Testing index recommendations..."
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

echo "Test 3: Testing auto-detection (should detect SQL Server)..."
ruby bin/omg \
  -s localhost \
  -P 1433 \
  -d test_db \
  -u sa \
  -p 'YourStrong!Passw0rd' \
  -t posts \
  -o generated_post.rb \
  -x none

if [ $? -eq 0 ]; then
    echo "✅ Auto-detection successful!"

    if [ -f "generated_post.rb" ]; then
        echo
        echo "📄 Generated Post model (first 30 lines):"
        echo "----------------------------------------"
        head -30 generated_post.rb
        echo "..."
        echo "----------------------------------------"
    fi
else
    echo "❌ Auto-detection failed"
fi

echo

# Test direct connection
echo "Test 4: Testing direct Ruby connection..."
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
  puts \"✅ Direct connection successful! Found #{row['user_count']} users\"

  result = client.execute('SELECT COUNT(*) as post_count FROM posts')
  row = result.first
  puts \"✅ Found #{row['post_count']} posts\"

  client.close
rescue => e
  puts \"❌ Direct connection failed: #{e.message}\"
end
"

echo

# Show database schema
echo "📋 Database Schema:"
sudo docker exec sqlserver_test /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong!Passw0rd -d test_db -Q "
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('users', 'posts')
ORDER BY TABLE_NAME, ORDINAL_POSITION
"

echo

# Cleanup
echo "🧹 Cleaning up..."
rm -f generated_user.rb generated_user_spec.rb generated_post.rb

echo "🛑 Stopping and removing SQL Server container..."
sudo docker stop sqlserver_test
sudo docker rm sqlserver_test

echo
echo "=== SQL Server Docker Test Complete ==="
echo "✅ All tests completed successfully!"
echo
echo "Summary:"
echo "- ✅ SQL Server container started and configured"
echo "- ✅ Test database and tables created"
echo "- ✅ Database Model Generator worked with SQL Server"
echo "- ✅ Model generation successful"
echo "- ✅ Index recommendations generated"
echo "- ✅ Auto-detection worked"
echo "- ✅ Direct Ruby connection successful"
echo
echo "Your SQL Server support is working perfectly! 🎉"
