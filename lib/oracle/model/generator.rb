require 'oci8'

module Oracle
  module Model
    class Generator
      VERSION = '0.1.0'

      attr_reader :connection
      attr_reader :constraints

      # Example:
      #
      #   connection = Oracle::Connection.new(user, password, database)
      #   ogenerator = Oracle::Model::Generator.new(connection)
      #   ogenerator.generate('users')
      #
      def initialize(connection)
        @connection   = connection
        @constraints  = []
        @primary_keys = []
      end

      def generate(table, view = false)
        get_constraints(table) unless view
      end

      private

      # Get the primary key. If there is more than one, then an array of
      # keys are returned.
      #
      def primary_keys
        @constraints.each{ |hash|
          if hash['CONSTRAINT_TYPE'] == 'P'
            @primary_keys << hash['COLUMN_NAME'].downcase
          end
        }

        if @primary_keys.size > 1
          @primary_keys.map{ |e| e.to_sym }
        else
          @primary_keys[0].to_sym
        end
      end

      # Get a list of constraints for a given table.
      #
      def get_constraints(table_name)
        sql = %Q{
          select *
          from all_cons_columns a, all_constraints b
          where a.owner = b.owner
          and a.constraint_name = b.constraint_name
          and a.table_name = b.table_name
          and b.table_name = '#{table_name.upcase}'
        }

        begin
          cursor = @connection.exec(sql)
          while rec = cursor.fetch_hash
            @constraints << rec
          end
        ensure
          cursor.close
        end
      end
    end
  end
end
