#############################################################################
# test_oracle_model_generator_docker.rb
#
# Test suite for the oracle-model-generator library adapted for Docker.
# This version uses environment variables for database connection and
# includes setup for containerized Oracle testing.
#############################################################################
require 'test-unit'
require 'oracle/model/generator'

class TC_Oracle_Model_Generator_Docker < Test::Unit::TestCase
  def setup
    # Use environment variables if available, otherwise fall back to defaults
    @host       = ENV['ORACLE_HOST'] || 'localhost'
    @port       = ENV['ORACLE_PORT'] || '1521'
    @sid        = ENV['ORACLE_SID'] || 'xe'
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
    rescue => e
      puts "Failed to connect to Oracle database: #{e.message}"
      puts "Connection details: #{@username}@#{@database}"
      puts "Make sure Oracle database is running and accessible"
      raise e
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
