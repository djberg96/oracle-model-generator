#!/usr/bin/env ruby

# Test script to verify Oracle Model Generator Docker environment
puts "Testing Oracle Model Generator Docker Environment"
puts "=" * 50

# Test 1: Check Ruby version
puts "\n1. Ruby Version:"
puts RUBY_VERSION

# Test 2: Check bundler and gems
puts "\n2. Checking ruby-oci8 gem installation:"
begin
  require 'oci8'
  puts "✓ ruby-oci8 gem loaded successfully"
  puts "  OCI8::VERSION: #{OCI8::VERSION}" if defined?(OCI8::VERSION)
rescue LoadError => e
  puts "✗ Failed to load ruby-oci8: #{e.message}"
  exit 1
end

# Test 3: Check Oracle Model Generator library
puts "\n3. Checking Oracle Model Generator library:"
begin
  require_relative '../lib/oracle-model-generator'
  puts "✓ Oracle Model Generator library loaded successfully"
rescue LoadError => e
  puts "✗ Failed to load Oracle Model Generator: #{e.message}"
  exit 1
end

# Test 4: Check Oracle environment variables
puts "\n4. Oracle Environment Variables:"
oracle_vars = %w[ORACLE_HOME LD_LIBRARY_PATH]
oracle_vars.each do |var|
  value = ENV[var]
  if value
    puts "  #{var}: #{value}"
  else
    puts "  #{var}: (not set)"
  end
end

# Test 5: Check Oracle Instant Client files
puts "\n5. Oracle Instant Client Installation:"
oracle_home = ENV['ORACLE_HOME']
if oracle_home && Dir.exist?(oracle_home)
  files = Dir.glob("#{oracle_home}/libclntsh.so*")
  if files.any?
    puts "✓ Oracle client libraries found:"
    files.each { |f| puts "  #{File.basename(f)}" }
  else
    puts "✗ Oracle client libraries not found"
  end
else
  puts "✗ Oracle home directory not found"
end

# Test 6: Database connection test (optional)
puts "\n6. Database Connection Test:"
db_host = ENV['ORACLE_HOST'] || 'localhost'
db_port = ENV['ORACLE_PORT'] || '1521'
db_sid = ENV['ORACLE_SID'] || 'XE'
db_user = ENV['ORACLE_USER'] || 'hr'
db_password = ENV['ORACLE_PASSWORD'] || 'hr'

puts "  Host: #{db_host}"
puts "  Port: #{db_port}"
puts "  SID: #{db_sid}"
puts "  User: #{db_user}"

begin
  conn_string = "#{db_user}/#{db_password}@#{db_host}:#{db_port}/#{db_sid}"
  conn = OCI8.new(conn_string)
  puts "✓ Successfully connected to Oracle database"

  # Simple test query
  cursor = conn.parse("SELECT 'Docker Test' as message FROM dual")
  cursor.exec
  result = cursor.fetch
  puts "✓ Test query result: #{result[0]}"

  cursor.close
  conn.logoff
rescue => e
  puts "⚠ Database connection failed (this is expected without a running database): #{e.message}"
end

puts "\n" + "=" * 50
puts "Docker environment test completed!"
puts "The Oracle Model Generator environment is ready for testing."
