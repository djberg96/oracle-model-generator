require 'database_model_generator'

# Shared context for database connection and test data
RSpec.shared_context 'Database connection' do
  before(:context) do
    @generator = create_generator
    setup_test_data if @generator
  end

  after(:context) do
    cleanup_test_data
    disconnect_generator
  end

  # Use a method instead of let for context-level variables
  def generator
    @generator
  end

  def connection
    @generator&.connection
  end

  private

  def create_generator
    database_type = ENV['DATABASE_TYPE'] || 'oracle'

    case database_type
    when 'oracle'
      create_oracle_generator
    when 'sqlserver'
      create_sqlserver_generator
    else
      skip "Unsupported database type: #{database_type}"
    end
  rescue LoadError => e
    skip "Database gem not available: #{e.message}"
  rescue => e
    skip "Database connection failed: #{e.message}"
  end

  def create_oracle_generator
    require 'oci8'

    host = ENV['ORACLE_HOST'] || 'localhost'
    port = ENV['ORACLE_PORT'] || '1521'
    sid = ENV['ORACLE_SID'] || 'freepdb1'
    database_str = "#{host}:#{port}/#{sid}"

    connection = OCI8.new(
      ENV['ORACLE_USER'] || 'hr',
      ENV['ORACLE_PASSWORD'] || 'hr',
      database_str
    )

    require_relative '../lib/oracle/model/generator'
    Oracle::Model::Generator.new(connection)
  end

  def create_sqlserver_generator
    require 'tiny_tds'

    connection = TinyTds::Client.new(
      username: ENV['SQLSERVER_USER'] || 'sa',
      password: ENV['SQLSERVER_PASSWORD'] || 'YourStrong!Passw0rd',
      host: ENV['SQLSERVER_HOST'] || 'localhost',
      port: ENV['SQLSERVER_PORT'] || 1433,
      database: ENV['SQLSERVER_DATABASE'] || 'master'
    )

    require_relative '../lib/sqlserver/model/generator'
    SqlServer::Model::Generator.new(connection)
  end

  def setup_test_data
    database_type = ENV['DATABASE_TYPE'] || 'oracle'

    case database_type
    when 'oracle'
      setup_oracle_test_data
    when 'sqlserver'
      setup_sqlserver_test_data
    end
  end

  def setup_oracle_test_data
    # Create basic test table if it doesn't exist
    connection.exec <<~SQL
      BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE test_employees (
          employee_id NUMBER PRIMARY KEY,
          first_name VARCHAR2(50) NOT NULL,
          last_name VARCHAR2(50) NOT NULL,
          email VARCHAR2(100) UNIQUE,
          hire_date DATE DEFAULT SYSDATE,
          department_id NUMBER,
          status VARCHAR2(20),
          CONSTRAINT chk_status CHECK (status IN (''active'', ''inactive'', ''pending''))
        )';
      EXCEPTION
        WHEN OTHERS THEN
          IF SQLCODE != -955 THEN -- Table already exists
            RAISE;
          END IF;
      END;
    SQL

    # Create a simple view
    connection.exec <<~SQL
      BEGIN
        EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW test_employee_view AS
          SELECT employee_id, first_name, last_name, email FROM test_employees';
      EXCEPTION
        WHEN OTHERS THEN
          NULL; -- Ignore errors for view creation
      END;
    SQL
  end

  def setup_sqlserver_test_data
    # Create basic test table if it doesn't exist
    connection.execute <<~SQL
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'test_employees')
      CREATE TABLE test_employees (
        employee_id INT IDENTITY(1,1) PRIMARY KEY,
        first_name NVARCHAR(50) NOT NULL,
        last_name NVARCHAR(50) NOT NULL,
        email NVARCHAR(100) UNIQUE,
        hire_date DATETIME2 DEFAULT GETDATE(),
        department_id INT,
        status NVARCHAR(20),
        CONSTRAINT chk_emp_status CHECK ([status] IS NOT DISTINCT FROM 'active' OR [status] IS NOT DISTINCT FROM 'inactive' OR [status] IS NOT DISTINCT FROM 'pending')
      );
    SQL

    # Create a simple view
    connection.execute <<~SQL
      IF NOT EXISTS (SELECT * FROM sys.views WHERE name = 'test_employee_view')
      EXEC('CREATE VIEW test_employee_view AS
        SELECT employee_id, first_name, last_name, email FROM test_employees');
    SQL
  end

  def cleanup_test_data
    return unless @generator

    database_type = ENV['DATABASE_TYPE'] || 'oracle'

    begin
      case database_type
      when 'oracle'
        cleanup_oracle_test_data
      when 'sqlserver'
        cleanup_sqlserver_test_data
      end
    rescue => e
      # Ignore cleanup errors
      warn "Cleanup failed: #{e.message}"
    end
  end

  def cleanup_oracle_test_data
    connection.exec("DROP VIEW test_employee_view") rescue nil
    connection.exec("DROP TABLE test_employees") rescue nil
  end

  def cleanup_sqlserver_test_data
    connection.execute("DROP VIEW IF EXISTS test_employee_view") rescue nil
    connection.execute("DROP TABLE IF EXISTS test_employees") rescue nil
  end

  def disconnect_generator
    @generator&.disconnect
    @generator = nil
  end
end
