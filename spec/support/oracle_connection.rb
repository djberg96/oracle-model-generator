require 'oci8'

# Shared context for Oracle database connection and test data
RSpec.shared_context 'Oracle connection' do
  before(:context) do
    @oracle_connection = begin
      # In Docker environment, use the service name instead of localhost
      host = ENV['ORACLE_HOST'] || 'localhost'
      port = ENV['ORACLE_PORT'] || '1521'
      sid = ENV['ORACLE_SID'] || 'freepdb1'
      database_str = "#{host}:#{port}/#{sid}"
      
      OCI8.new(
        ENV['ORACLE_USER'] || 'hr',
        ENV['ORACLE_PASSWORD'] || 'oracle',
        database_str
      )
    rescue OCIError => e
      warn "Database connection failed: #{e.message}"
      warn "Make sure Oracle database is running and accessible"
      warn "Connection string: #{ENV['ORACLE_HOST'] || 'localhost'}:#{ENV['ORACLE_PORT'] || '1521'}/#{ENV['ORACLE_SID'] || 'freepdb1'}"
      warn "User: #{ENV['ORACLE_USER'] || 'hr'}"
      raise e
    end
    setup_test_data
  end

  after(:context) do
    # Cleanup test tables and views
    cleanup_test_data
    
    # Close the connection
    @oracle_connection&.logoff
  end

  # Use a method instead of let for context-level variables
  def connection
    @oracle_connection
  end

  private

  def setup_test_data
    # Create test tables and views if they don't exist
    setup_sample_data
  end

  def cleanup_test_data
    # Drop test views first (to avoid dependency issues)
    begin
      @oracle_connection.exec('DROP VIEW hr.employees_by_department') rescue nil
    rescue => e
      # Ignore errors if views don't exist
    end

    # Note: We don't drop HR schema tables as they might be used by other tests
  end

  def setup_sample_data
    # Check if employees table exists and has data
    begin
      cursor = @oracle_connection.parse('SELECT COUNT(*) FROM employees')
      cursor.exec
      count = cursor.fetch[0]
      cursor.close

      if count == 0
        # Insert sample data into employees table
        @oracle_connection.exec(<<~SQL)
          INSERT INTO employees (employee_id, first_name, last_name, email, phone_number,
                               hire_date, job_id, salary, commission_pct, manager_id, department_id)
          VALUES (1, 'John', 'Doe', 'john.doe@example.com', '555-1234',
                  DATE '2020-01-15', 'IT_PROG', 5000, NULL, NULL, 60)
        SQL

        @oracle_connection.exec(<<~SQL)
          INSERT INTO employees (employee_id, first_name, last_name, email, phone_number,
                               hire_date, job_id, salary, commission_pct, manager_id, department_id)
          VALUES (2, 'Jane', 'Smith', 'jane.smith@example.com', '555-5678',
                  DATE '2021-03-10', 'IT_PROG', 5500, NULL, 1, 60)
        SQL

        @oracle_connection.commit
      end

      # Check if departments table exists and has data
      cursor = @oracle_connection.parse('SELECT COUNT(*) FROM departments')
      cursor.exec
      dept_count = cursor.fetch[0]
      cursor.close

      if dept_count == 0
        # Insert sample data into departments table
        @oracle_connection.exec(<<~SQL)
          INSERT INTO departments (department_id, department_name, manager_id, location_id)
          VALUES (60, 'IT', 1, 1700)
        SQL

        @oracle_connection.exec(<<~SQL)
          INSERT INTO departments (department_id, department_name, manager_id, location_id)
          VALUES (50, 'Shipping', NULL, 1500)
        SQL

        @oracle_connection.commit
      end

      # Create a test view if it doesn't exist
      begin
        @oracle_connection.exec(<<~SQL)
          CREATE OR REPLACE VIEW hr.employees_by_department AS
          SELECT e.employee_id, e.first_name, e.last_name, e.email,
                 d.department_name, d.department_id
          FROM employees e
          JOIN departments d ON e.department_id = d.department_id
        SQL
      rescue => e
        # View creation might fail if tables don't exist yet, that's okay
        warn "Could not create test view: #{e.message}"
      end

    rescue => e
      warn "Could not set up sample data: #{e.message}"
      # Continue with tests even if sample data setup fails
    end
  end
end
