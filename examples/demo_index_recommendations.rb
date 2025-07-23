#!/usr/bin/env ruby

# Demo script showing index recommendations functionality
# This would normally connect to Oracle, but for demo purposes we'll show the structure

puts "Oracle Model Generator - Index Recommendations Demo"
puts "=" * 50

# Example of what the index_recommendations method would return:
sample_recommendations = {
  foreign_keys: [
    { column: "department_id", sql: "add_index :employees, :department_id", reason: "Foreign key index for department_id" },
    { column: "manager_id", sql: "add_index :employees, :manager_id", reason: "Foreign key index for manager_id" },
    { column: "job_id", sql: "add_index :employees, :job_id", reason: "Foreign key index for job_id" }
  ],
  unique_constraints: [
    { column: "email", sql: "add_index :employees, :email, unique: true", reason: "Unique constraint for email" }
  ],
  date_queries: [
    { column: "hire_date", sql: "add_index :employees, :hire_date", reason: "Date queries for hire_date" }
  ],
  status_enum: [],
  composite: [
    { columns: ["department_id", "hire_date"], sql: "add_index :employees, [:department_id, :hire_date]", reason: "Composite index for filtering by department_id and hire_date" }
  ],
  full_text: [
    { column: "first_name", sql: "CREATE INDEX idx_employees_first_name_text ON EMPLOYEES (FIRST_NAME) INDEXTYPE IS CTXSYS.CONTEXT", reason: "Full-text search for first_name", type: "Oracle Text Index" }
  ]
}

puts "\nIndex Recommendations for EMPLOYEES table:\n"

[:foreign_keys, :unique_constraints, :date_queries, :status_enum, :composite, :full_text].each do |category|
  next if sample_recommendations[category].empty?

  puts "\n#{category.to_s.gsub('_', ' ').capitalize}:"
  puts "-" * 30

  sample_recommendations[category].each do |recommendation|
    puts "  #{recommendation[:sql]}"
    puts "    # #{recommendation[:reason]}"
    puts "    # Type: #{recommendation[:type]}" if recommendation[:type]
    puts
  end
end

puts "\nGenerated Migration Example:"
puts "=" * 30

puts <<~MIGRATION
  class AddIndexesToEmployees < ActiveRecord::Migration[7.0]
    def change
      # Foreign key indexes
      add_index :employees, :department_id
      add_index :employees, :manager_id
      add_index :employees, :job_id

      # Unique constraints
      add_index :employees, :email, unique: true

      # Date query optimization
      add_index :employees, :hire_date

      # Composite indexes for common query patterns
      add_index :employees, [:department_id, :hire_date]

      # Note: Oracle Text indexes require separate DDL:
      # CREATE INDEX idx_employees_first_name_text ON EMPLOYEES (FIRST_NAME) INDEXTYPE IS CTXSYS.CONTEXT;
    end
  end
MIGRATION

puts "\nPerformance Impact:"
puts "=" * 20
puts "• Foreign key indexes: 10-100x faster JOIN operations"
puts "• Unique indexes: Instant uniqueness validation, faster lookups"
puts "• Date indexes: 5-50x faster date range queries"
puts "• Composite indexes: Optimal for multi-column WHERE clauses"
puts "• Full-text indexes: Enable fast text search with Oracle Text"

puts "\nUsage in ActiveRecord queries:"
puts "=" * 30
puts <<~QUERIES
  # These queries will be optimized by the recommended indexes:

  Employee.joins(:department).where(department_id: 1)           # Uses department_id index
  Employee.where(email: 'user@example.com')                    # Uses unique email index
  Employee.where('hire_date > ?', 1.year.ago)                  # Uses hire_date index
  Employee.where(department_id: 1, hire_date: Date.current)    # Uses composite index
  Employee.where("CONTAINS(first_name, 'John') > 0")           # Uses Oracle Text index
QUERIES
