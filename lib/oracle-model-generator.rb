require_relative 'database_model_generator'
require_relative 'oracle/model/generator'
require_relative 'sqlserver/model/generator'

# Maintain backward compatibility
module Oracle
  module Model
    # Generator alias is already defined in oracle/model/generator.rb
  end
end
