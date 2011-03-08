require 'oci8'

module Oracle
  module Model
    class Generator
      VERSION = '0.2.0'

      attr_reader :connection
      attr_reader :constraints
      attr_reader :foreign_keys
      attr_reader :belongs_to
      attr_reader :table
      attr_reader :view
      attr_reader :dependencies
      attr_reader :column_info
      attr_reader :primary_keys

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
        @foreign_keys = []
        @dependencies = []
        @belongs_to   = []
        @column_info  = []
        @table        = nil
      end

      # Generates an Oracle::Model::Generator object for +table+. If this is
      # a view (materialized or otherwise), set the +view+ argument to true.
      #
      # This method does not actually generate a file of any sort. It merely
      # sets instance variables which you can then use in your own class/file
      # generation programs.
      #
      def generate(table, view = false)
        @table = table.split('_').map{ |e| e.downcase.capitalize }.join
        @view  = view
        get_constraints(table) unless view
        get_foreign_keys unless view
        get_column_info(table) unless view
        get_primary_keys
      end

      private

      def get_column_info(table_name)
        table = @connection.describe_table(table_name)
        table.columns.each{ |col| @column_info << col }
      end

      # Returns an array of primary keys.
      #
      def get_primary_keys
        @constraints.each{ |hash|
          if hash['CONSTRAINT_TYPE'] == 'P'
            @primary_keys << hash['COLUMN_NAME'].downcase
          end
        }
      end

      # Returns an array of foreign keys.
      #
      def get_foreign_keys
        @constraints.each{ |hash|
          if hash['CONSTRAINT_TYPE'] == 'R'
            @foreign_keys << hash['R_CONSTRAINT_NAME']
          end
        }

        get_belongs_to()
      end

      # Returns an array of tables that the current table has foreign key
      # ties to.
      #
      def get_belongs_to
        @foreign_keys.each{ |fk|
          @belongs_to << find_fk_table(fk)
        }
      end

      # Find table name based on a foreign key name.
      #
      def find_fk_table(fk)
        sql = %Q{
          select table_name
          from all_constraints
          where constraint_name = '#{fk}'
        }

        begin
          cursor = @connection.exec(sql)
          table = cursor.fetch.first
        ensure
          cursor.close if cursor
        end

        table
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
          cursor.close if cursor
        end
      end

    end
  end
end
