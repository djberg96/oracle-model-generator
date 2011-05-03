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
    assert_equal('0.2.1', Oracle::Model::Generator::VERSION)
  end

  test "constructor accepts an oci8 connection object" do
    assert_nothing_raised{ @generator = Oracle::Model::Generator.new(@connection) }
  end

  test "generate method basic functionality" do
    assert_nothing_raised{ @generator = Oracle::Model::Generator.new(@connection) }
    assert_respond_to(@generator, :generate)
  end

  test "generate method works with a table name or view" do
    assert_nothing_raised{ @generator = Oracle::Model::Generator.new(@connection) }
    assert_nothing_raised{ @generator.generate('employees') }
    assert_nothing_raised{ @generator.generate('emp_details_view', true) }
  end

  def teardown
    @username  = nil
    @password  = nil
    @database  = nil
    @generator = nil
    @connection.logoff if @connection
  end
end
