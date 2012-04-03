require 'oci8'

module Oracle
  module Model
    class Generator
      # The version of the oracle-model-generator library
      VERSION = '0.3.1'

      # The raw OCI8 connection.
      attr_reader :connection

      # An array of hashes that contain per-column constraint information.
      attr_reader :constraints

      # An array of foreign key names.
      attr_reader :foreign_keys

      # An array of parent tables that the table has a foreign key
      # relationship with.
      attr_reader :belongs_to

      # The table name associated with the generator.
      attr_reader :table

      # The name of the active record model to be generated.
      attr_reader :model

      # Boolean indicating whether the generator is for a regular table or a view.
      attr_reader :view

      # A list of dependencies for the table.
      attr_reader :dependencies

      # An array of raw OCI::Metadata::Column objects.
      attr_reader :column_info

      # An array of primary keys for the column. May contain one or more values.
      attr_reader :primary_keys

      # Creates and returns a new Oracle::Model::Generator object. It accepts
      # an Oracle::Connection object, which is what OCI8.new returns.
      #
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
        @model        = nil
      end

      # Generates an Oracle::Model::Generator object for +table+. If this is
      # a view (materialized or otherwise), set the +view+ argument to true.
      #
      # This method does not actually generate a file of any sort. It merely
      # sets instance variables which you can then use in your own class/file
      # generation programs.
      #--
      # Makes a best guess as to the model name. I'm not going to put too much
      # effort into this. It's much easier for you to hand edit a class name
      # than it is for me to parse English.
      #
      def generate(table, view = false)
        @table = table.upcase
        @model = table.split('_').map{ |e| e.downcase.capitalize }.join
        @view  = view

        # Remove trailing 's'
        @model.chop! if @model[-1].chr.upcase == 'S'

        unless view
          get_constraints
          get_foreign_keys
          get_column_info
        end

        get_primary_keys
        get_dependencies
      end

      private

      def get_column_info
        table = @connection.describe_table(@table)
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
      def get_constraints
        sql = %Q{
          select *
          from all_cons_columns a, all_constraints b
          where a.owner = b.owner
          and a.constraint_name = b.constraint_name
          and a.table_name = b.table_name
          and b.table_name = '#{@table}'
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

      # An array of hashes indicating objects that are dependent on the table.
      #
      def get_dependencies
        sql = %Q{
          select *
          from all_dependencies dep
          where referenced_name = '#{@table}'
        }

        begin
          cursor = @connection.exec(sql)
          while rec = cursor.fetch_hash
            @dependencies << rec
          end
        ensure
          cursor.close if cursor
        end
      end

    end
  end
end
