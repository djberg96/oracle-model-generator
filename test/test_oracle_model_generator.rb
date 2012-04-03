#############################################################################
# test_oracle_model_generator.rb
#
# Test suite for the oracle-model-generator library. For testing purposes
# I'm using the 'hr' database that comes as part of the Oracle Express
# edition which you can download from oracle.com. Adjust as necessary.
#############################################################################
require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'oracle/model/generator'

class TC_Oracle_Model_Generator < Test::Unit::TestCase
  def setup
    @username   = 'hr'
    @password   = 'hr'
    @database   = 'xe'
    @generator  = nil
    @connection = OCI8.new(@username, @password, @database)
  end

  test "version number is correct" do
    assert_equal('0.3.1', Oracle::Model::Generator::VERSION)
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
