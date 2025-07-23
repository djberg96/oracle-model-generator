#!/usr/bin/env ruby

require 'tiny_tds'

begin
  puts "Testing TinyTds connection..."

  client = TinyTds::Client.new(
    username: 'sa',
    password: 'TestPassword123!',
    host: 'localhost',
    port: 1433
  )

  puts "✅ Connected successfully"

  # Test basic query
  result = client.execute("SELECT @@VERSION")
  puts "✅ Basic query works"

  row = result.first
  puts "SQL Server Version: #{row.values.first}" if row

  # Test database creation
  result = client.execute("CREATE DATABASE debugtest")
  result.do  # Consume the result
  puts "✅ Database created"

  # Switch to the database
  result = client.execute("USE debugtest")
  result.do  # Consume the result
  puts "✅ Using debugtest database"

  # Create a test table
  result = client.execute("CREATE TABLE test_table (id INT IDENTITY(1,1) PRIMARY KEY, name VARCHAR(50))")
  result.do  # Consume the result
  puts "✅ Test table created"

  # Test the problematic query pattern
  table_name = 'test_table'
  sql = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '#{table_name}'"

  result = client.execute(sql)
  puts "✅ Column query works"

  result.each do |row|
    puts "Column: #{row['COLUMN_NAME']}"
  end

  client.close
  puts "✅ Connection closed successfully"

rescue => e
  puts "❌ Error: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(5)
end
