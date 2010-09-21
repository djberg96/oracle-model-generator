require 'oci8'

module Oracle
  module Model
    class Generator
      VERSION = '0.1.0'

      attr_reader :connection

      # Example:
      #
      #   connection = Oracle::Connection.new(user, password, database)
      #   ogenerator = Oracle::Model::Generator.new(connection)
      #   ogenerator.generate('users')
      #
      def initialize(connection)
        @connection = connection
      end

      def generate(table, view = false)
      end
    end
  end
end
