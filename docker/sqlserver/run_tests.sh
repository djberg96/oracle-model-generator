#!/bin/bash

echo "=== SQL Server Database Model Generator Test Suite ==="
echo "Waiting for SQL Server to be ready..."

# Wait for SQL Server to be fully ready
sleep 10

echo "Testing SQL Server connectivity..."
ruby -e "
require 'tiny_tds'
begin
  client = TinyTds::Client.new(
    username: ENV['SQLSERVER_USERNAME'],
    password: ENV['SQLSERVER_PASSWORD'],
    host: ENV['SQLSERVER_HOST'],
    port: ENV['SQLSERVER_PORT'].to_i,
    database: ENV['SQLSERVER_DATABASE']
  )
  result = client.execute('SELECT 1 as test')
  puts '✓ SQL Server connection successful'
  client.close
rescue => e
  puts \"✗ SQL Server connection failed: #{e.message}\"
  exit 1
end
"

echo
echo "=== Testing Database Model Generator with SQL Server ==="
echo

# Test 1: Generate User model
echo "1. Testing User model generation..."
ruby bin/omg \
  -T sqlserver \
  -s $SQLSERVER_HOST \
  -P $SQLSERVER_PORT \
  -d $SQLSERVER_DATABASE \
  -u $SQLSERVER_USERNAME \
  -p $SQLSERVER_PASSWORD \
  -t users \
  -o user_model.rb \
  -x rspec

if [ $? -eq 0 ]; then
  echo "✓ User model generated successfully"
  echo "Generated files:"
  ls -la user_model.rb user_model_spec.rb 2>/dev/null || echo "  Files not found"
else
  echo "✗ User model generation failed"
fi

echo

# Test 2: Generate Post model
echo "2. Testing Post model generation..."
ruby bin/omg \
  -T sqlserver \
  -s $SQLSERVER_HOST \
  -P $SQLSERVER_PORT \
  -d $SQLSERVER_DATABASE \
  -u $SQLSERVER_USERNAME \
  -p $SQLSERVER_PASSWORD \
  -t posts \
  -o post_model.rb \
  -x minitest

if [ $? -eq 0 ]; then
  echo "✓ Post model generated successfully"
else
  echo "✗ Post model generation failed"
fi

echo

# Test 3: Test index recommendations
echo "3. Testing index recommendations..."
ruby bin/omg \
  -T sqlserver \
  -s $SQLSERVER_HOST \
  -P $SQLSERVER_PORT \
  -d $SQLSERVER_DATABASE \
  -u $SQLSERVER_USERNAME \
  -p $SQLSERVER_PASSWORD \
  -t comments \
  -i

if [ $? -eq 0 ]; then
  echo "✓ Index recommendations generated successfully"
else
  echo "✗ Index recommendations failed"
fi

echo

# Test 4: Test auto-detection (should detect SQL Server)
echo "4. Testing database type auto-detection..."
ruby bin/omg \
  -s $SQLSERVER_HOST \
  -P $SQLSERVER_PORT \
  -d $SQLSERVER_DATABASE \
  -u $SQLSERVER_USERNAME \
  -p $SQLSERVER_PASSWORD \
  -t categories \
  -o category_model.rb \
  -x none

if [ $? -eq 0 ]; then
  echo "✓ Auto-detection worked (SQL Server detected)"
else
  echo "✗ Auto-detection failed"
fi

echo

# Show generated model samples
echo "=== Generated Model Samples ==="
echo

if [ -f "user_model.rb" ]; then
  echo "User model (first 30 lines):"
  head -30 user_model.rb
  echo "..."
  echo
fi

if [ -f "post_model.rb" ]; then
  echo "Post model (first 20 lines):"
  head -20 post_model.rb
  echo "..."
  echo
fi

# Show test files
echo "=== Generated Test Files ==="
echo

if [ -f "user_model_spec.rb" ]; then
  echo "RSpec test file (first 15 lines):"
  head -15 user_model_spec.rb
  echo "..."
  echo
fi

if [ -f "test_post_model.rb" ]; then
  echo "Minitest file (first 15 lines):"
  head -15 test_post_model.rb
  echo "..."
  echo
fi

echo "=== Test Suite Complete ==="
echo "All tests completed. Check the output above for results."
