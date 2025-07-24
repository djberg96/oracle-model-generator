# Load the library we're testing
require_relative '../lib/database_model_generator'

# RSpec configuration for Database Model Generator
RSpec.configure do |config|
  # Use the expect() syntax rather than should syntax
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Use the new mock framework syntax
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Enable color output
  config.color = true

  # Use documentation format for output
  config.formatter = :documentation

  # Skip tests if database connection fails
  config.before(:suite) do
    database_type = ENV['DATABASE_TYPE'] || 'oracle'
    puts "Running tests with #{database_type} database"
  end

  # Run specs in random order to surface order dependencies
  config.order = :random

  # Allow filtering tests by tags
  config.filter_run_when_matching :focus

  # Shared context for setting up test data
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
