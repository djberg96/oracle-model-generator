#############################################################################
# test_oracle_model_generator_docker.rb
#
# Test suite for the oracle-model-generator library adapted for Docker.
# This version uses environment variables for database connection and
# includes setup for containerized Oracle testing.
#############################################################################
require 'test-unit'
require 'oracle/model/generator'

class TC_Oracle_Model_Generator < Test::Unit::TestCase
  def setup
    # Use environment variables if available, otherwise fall back to defaults
    @host       = ENV['ORACLE_HOST'] || 'localhost'
    @port       = ENV['ORACLE_PORT'] || '1521'
    @sid        = ENV['ORACLE_SID'] || 'freepdb1'  # Use freepdb1 for Docker
    @username   = ENV['ORACLE_USER'] || 'hr'
    @password   = ENV['ORACLE_PASSWORD'] || 'hr'
    @generator  = nil

    # Build connection string for Docker environment
    if @host != 'localhost'
      @database = "//#{@host}:#{@port}/#{@sid}"
    else
      @database = @sid
    end

    begin
      @connection = OCI8.new(@username, @password, @database)
      setup_test_data  # Automatically setup test data
    rescue => e
      puts "Failed to connect to Oracle database: #{e.message}"
      puts "Connection details: #{@username}@#{@database}"
      puts "Make sure Oracle database is running and accessible"
      raise e
    end
  end

  private

  def setup_test_data
    # Setup test tables and data if they don't exist
    setup_tables
    setup_sample_data
    setup_views
  end

  def setup_tables
    # Create employees table
    begin
      @connection.exec('CREATE TABLE employees (
        employee_id NUMBER(6) PRIMARY KEY,
        first_name VARCHAR2(20),
        last_name VARCHAR2(25) NOT NULL,
        email VARCHAR2(25) NOT NULL UNIQUE,
        phone_number VARCHAR2(20),
        hire_date DATE NOT NULL,
        job_id VARCHAR2(10) NOT NULL,
        salary NUMBER(8,2),
        commission_pct NUMBER(2,2),
        manager_id NUMBER(6),
        department_id NUMBER(4)
      )')
    rescue => e
      # Table might already exist, that's OK
    end

    # Create departments table
    begin
      @connection.exec('CREATE TABLE departments (
        department_id NUMBER(4) PRIMARY KEY,
        department_name VARCHAR2(30) NOT NULL,
        manager_id NUMBER(6),
        location_id NUMBER(4)
      )')
    rescue => e
      # Table might already exist, that's OK
    end
  end

  def setup_sample_data
    # Check if data already exists
    cursor = @connection.parse('SELECT COUNT(*) FROM employees')
    cursor.exec
    count = cursor.fetch[0]
    cursor.close

    return if count > 0  # Data already exists

    # Insert sample data
    begin
      @connection.exec("INSERT INTO employees VALUES (100, 'Steven', 'King', 'SKING', '515.123.4567', SYSDATE, 'AD_PRES', 24000, NULL, NULL, 90)")
      @connection.exec("INSERT INTO employees VALUES (101, 'Neena', 'Kochhar', 'NKOCHHAR', '515.123.4568', SYSDATE, 'AD_VP', 17000, NULL, 100, 90)")
      @connection.exec("INSERT INTO employees VALUES (102, 'Lex', 'De Haan', 'LDEHAAN', '515.123.4569', SYSDATE, 'AD_VP', 17000, NULL, 100, 90)")
      @connection.exec("INSERT INTO employees VALUES (103, 'Alexander', 'Hunold', 'AHUNOLD', '590.423.4567', SYSDATE, 'IT_PROG', 9000, NULL, 102, 60)")
      @connection.exec("INSERT INTO employees VALUES (104, 'Bruce', 'Ernst', 'BERNST', '590.423.4568', SYSDATE, 'IT_PROG', 6000, NULL, 103, 60)")
      
      @connection.exec("INSERT INTO departments VALUES (90, 'Executive', 100, 1700)")
      @connection.exec("INSERT INTO departments VALUES (60, 'IT', 103, 1400)")
      @connection.exec("INSERT INTO departments VALUES (50, 'Shipping', 121, 1500)")
      
      @connection.commit
    rescue => e
      # Data might already exist, that's OK
    end
  end

  def setup_views
    # Create emp_details_view
    begin
      @connection.exec('CREATE VIEW emp_details_view AS 
        SELECT employee_id, first_name, last_name, email, hire_date, job_id, salary 
        FROM employees')
    rescue => e
      # View might already exist, that's OK
    end

    # Create department_employees view
    begin
      @connection.exec('CREATE VIEW department_employees AS
        SELECT d.department_name, e.first_name, e.last_name, e.salary
        FROM departments d
        JOIN employees e ON d.department_id = e.department_id')
    rescue => e
      # View might already exist, that's OK
    end
  end

  test "version number is correct" do
    assert_equal('0.4.1', Oracle::Model::Generator::VERSION)
  end

  test "constructor accepts an oci8 connection object" do
    assert_nothing_raised{ @generator = Oracle::Model::Generator.new(@connection) }
  end

  test "generate method basic functionality" do
    assert_nothing_raised{ @generator = Oracle::Model::Generator.new(@connection) }
    assert_respond_to(@generator, :generate)
  end

  test "generate method works with a table name or view" do
    @generator = Oracle::Model::Generator.new(@connection)
    assert_nothing_raised{ @generator.generate('employees') }
    assert_nothing_raised{ @generator.generate('emp_details_view', true) }
  end

  test "model method returns active record model name" do
    @generator = Oracle::Model::Generator.new(@connection)
    @generator.generate('emp_details_view', true)
    assert_respond_to(@generator, :model)
    assert_equal('EmpDetailsView', @generator.model)
  end

  test "table method returns uppercased table name passed to generate method" do
    @generator = Oracle::Model::Generator.new(@connection)
    @generator.generate('emp_details_view', true)
    assert_respond_to(@generator, :table)
    assert_equal('EMP_DETAILS_VIEW', @generator.table)
  end

  test "dependencies method returns an array of hashes" do
    @generator = Oracle::Model::Generator.new(@connection)
    @generator.generate('employees', true)
    assert_respond_to(@generator, :dependencies)
    assert_kind_of(Array, @generator.dependencies)
    assert_kind_of(Hash, @generator.dependencies.first)
  end

  def teardown
    @username  = nil
    @password  = nil
    @database  = nil
    @generator = nil
    @connection.logoff if @connection
  end
end
