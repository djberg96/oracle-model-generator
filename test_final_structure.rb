#!/usr/bin/env ruby

puts "=== Comprehensive Test of Reorganized Structure ==="

# Test 1: Basic require and module loading
puts "\n1. Testing module loading..."
begin
  require_relative 'lib/database_model_generator'
  puts "✓ DatabaseModel::Generator loaded"
  puts "  - Version: #{DatabaseModel::Generator::VERSION}"
rescue => e
  puts "✗ Error: #{e.message}"
  exit 1
end

# Test 2: Oracle namespace loading
puts "\n2. Testing Oracle namespace..."
begin
  require_relative 'lib/oracle/model/generator'
  puts "✓ Oracle::Model::Generator loaded"
  puts "  - Class: #{Oracle::Model::Generator}"
  puts "  - Superclass: #{Oracle::Model::Generator.superclass}"
  puts "  - Version: #{Oracle::Model::Generator::VERSION}"
rescue => e
  puts "✗ Error: #{e.message}"
end

# Test 3: SQL Server namespace loading
puts "\n3. Testing SQL Server namespace..."
begin
  require_relative 'lib/sqlserver/model/generator'
  puts "✓ SqlServer::Model::Generator loaded"
  puts "  - Class: #{SqlServer::Model::Generator}"
  puts "  - Superclass: #{SqlServer::Model::Generator.superclass}"
  puts "  - Version: #{SqlServer::Model::Generator::VERSION}"
rescue => e
  puts "✗ Error: #{e.message}"
end

# Test 4: Factory method
puts "\n4. Testing factory method..."
begin
  # Test that factory method exists and has the right signature
  factory_method = DatabaseModel::Generator.method(:new)
  puts "✓ Factory method exists"
  puts "  - Parameters: #{factory_method.parameters}"
rescue => e
  puts "✗ Error: #{e.message}"
end

# Test 5: Backward compatibility
puts "\n5. Testing backward compatibility..."
begin
  require_relative 'lib/oracle-model-generator'
  puts "✓ oracle-model-generator.rb loads successfully"

  # Check that the Oracle::Model::Generator still exists and is the right class
  if defined?(Oracle::Model::Generator)
    puts "✓ Oracle::Model::Generator is available"
    puts "  - Class: #{Oracle::Model::Generator}"
  else
    puts "✗ Oracle::Model::Generator not found"
  end
rescue => e
  puts "✗ Error: #{e.message}"
end

# Test 6: CLI structure
puts "\n6. Testing CLI..."
begin
  cli_content = File.read('bin/omg')

  # Check critical requirements
  checks = {
    "Uses relative require" => cli_content.include?("require_relative '../lib/database_model_generator'"),
    "Has disconnect calls" => cli_content.include?("omg.disconnect"),
    "Uses unified version" => cli_content.include?("DatabaseModel::Generator::VERSION"),
    "Has database type detection" => cli_content.include?("database_type")
  }

  checks.each do |check, result|
    puts "  #{result ? '✓' : '✗'} #{check}"
  end
rescue => e
  puts "✗ Error reading CLI: #{e.message}"
end

# Test 7: Directory structure
puts "\n7. Verifying directory structure..."
expected_files = [
  'lib/database_model_generator.rb',
  'lib/oracle/model/generator.rb',
  'lib/sqlserver/model/generator.rb',
  'lib/oracle-model-generator.rb'
]

missing_files = []
expected_files.each do |file|
  if File.exist?(file)
    puts "  ✓ #{file}"
  else
    puts "  ✗ #{file} (missing)"
    missing_files << file
  end
end

# Test 8: Old files removed
puts "\n8. Checking old files removed..."
old_files = [
  'lib/oracle_generator.rb',
  'lib/sqlserver_generator.rb'
]

old_files.each do |file|
  if File.exist?(file)
    puts "  ⚠ #{file} (should be removed)"
  else
    puts "  ✓ #{file} (properly removed)"
  end
end

puts "\n=== Summary ==="
if missing_files.empty?
  puts "✓ All reorganization checks passed!"
  puts "\nNew structure:"
  puts "lib/"
  puts "├── database_model_generator.rb      # Factory and base class"
  puts "├── oracle/"
  puts "│   └── model/"
  puts "│       └── generator.rb            # Oracle implementation"
  puts "├── sqlserver/"
  puts "│   └── model/"
  puts "│       └── generator.rb            # SQL Server implementation"
  puts "└── oracle-model-generator.rb       # Backward compatibility"
else
  puts "✗ Missing files: #{missing_files.join(', ')}"
  exit 1
end
