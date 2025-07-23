require_relative '../../database_model_generator'

begin
  require 'oci8'
rescue LoadError
  # OCI8 not available - Oracle support will be disabled
end

module Oracle
  module Model
    class Generator < DatabaseModel::Generator::Base
      VERSION = DatabaseModel::Generator::VERSION

      private

      def validate_connection(connection)
        unless defined?(OCI8) && connection.is_a?(OCI8)
          raise ArgumentError, "Connection must be an OCI8 object. Install 'oci8' gem for Oracle support."
        end
      end

      def normalize_table_name(table)
        table.upcase
      end

      def check_table_exists(table)
        cursor = nil
        begin
          sql = "SELECT COUNT(*) FROM USER_TABLES WHERE TABLE_NAME = ?"
          cursor = @connection.parse(sql)
          cursor.bind_param(1, table.upcase)
          cursor.exec
          result = cursor.fetch
          result && result[0] > 0
        rescue => e
          puts "Error checking table existence: #{e.message}"
          false
        ensure
          cursor.close if cursor
        end
      end

<<<<<<< Updated upstream
      # Public method to get readable constraint information
      def constraint_summary
        return {} unless generated?

        summary = Hash.new { |h, k| h[k] = [] }
        @constraints.each do |constraint|
          type = case constraint['CONSTRAINT_TYPE']
                 when 'P' then 'Primary Key'
                 when 'R' then 'Foreign Key'
                 when 'U' then 'Unique'
                 when 'C' then 'Check'
                 else constraint['CONSTRAINT_TYPE']
                 end
          summary[constraint['COLUMN_NAME'].downcase] << type
        end
        summary
      end

      private

      # Reset internal state - useful for error recovery
      def reset_state
        @constraints.clear
        @primary_keys.clear
        @foreign_keys.clear
        @dependencies.clear
        @belongs_to.clear
        @column_info.clear
        @table = nil
        @model = nil
        @view = nil
      end

      # Generate a more intelligent model name from table name
      def generate_model_name(table)
        # Handle common table naming patterns
        name = table.split('_').map{ |part| part.downcase.capitalize }.join

        # Remove trailing 's' for pluralized table names
        name.chop! if name.length > 1 && name[-1].chr.upcase == 'S'

        # Handle special cases
        case name.downcase
        when 'people'
          'Person'
        when 'children'
          'Child'
        when 'data'
          'Datum'
        else
          name
        end
      end

=======
>>>>>>> Stashed changes
      def get_column_info
        cursor = nil
        begin
          if @view
            sql = "SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, DATA_SCALE, NULLABLE
                   FROM USER_TAB_COLUMNS WHERE TABLE_NAME = ? ORDER BY COLUMN_ID"
          else
            sql = "SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, DATA_SCALE, NULLABLE
                   FROM USER_TAB_COLUMNS WHERE TABLE_NAME = ? ORDER BY COLUMN_ID"
          end

          cursor = @connection.parse(sql)
          cursor.bind_param(1, @table)
          cursor.exec

          @column_info = []
          while row = cursor.fetch_hash
            @column_info << OracleColumnInfo.new(row)
          end
        rescue => e
          raise "Error retrieving column information: #{e.message}"
        ensure
          cursor.close if cursor
        end
      end

      def get_primary_keys
        cursor = nil
        begin
          sql = "SELECT column_name FROM user_cons_columns
                 WHERE constraint_name = (
                   SELECT constraint_name FROM user_constraints
                   WHERE table_name = ? AND constraint_type = 'P'
                 ) ORDER BY position"

          cursor = @connection.parse(sql)
          cursor.bind_param(1, @table)
          cursor.exec

          @primary_keys = []
          while row = cursor.fetch
            @primary_keys << row[0]
          end
        rescue => e
          raise "Error retrieving primary keys: #{e.message}"
        ensure
          cursor.close if cursor
        end
      end

      def get_foreign_keys
        cursor = nil
        begin
          sql = "SELECT column_name FROM user_cons_columns
                 WHERE constraint_name IN (
                   SELECT constraint_name FROM user_constraints
                   WHERE table_name = ? AND constraint_type = 'R'
                 )"

          cursor = @connection.parse(sql)
          cursor.bind_param(1, @table)
          cursor.exec

          @foreign_keys = []
          while row = cursor.fetch
            @foreign_keys << row[0]
          end
        rescue => e
          raise "Error retrieving foreign keys: #{e.message}"
        ensure
          cursor.close if cursor
        end
      end

      def get_constraints
        cursor = nil
        begin
          sql = "SELECT c.constraint_name, c.constraint_type, cc.column_name, c.search_condition
                 FROM user_constraints c, user_cons_columns cc
                 WHERE c.table_name = ? AND c.constraint_name = cc.constraint_name"

          cursor = @connection.parse(sql)
          cursor.bind_param(1, @table)
          cursor.exec

          @constraints = []
          while row = cursor.fetch_hash
            @constraints << row
          end
        rescue => e
          raise "Error retrieving constraints: #{e.message}"
        ensure
          cursor.close if cursor
        end
      end

      def get_dependencies
        cursor = nil
        begin
          sql = "SELECT REFERENCED_NAME as NAME, REFERENCED_TYPE as TYPE
                 FROM USER_DEPENDENCIES WHERE NAME = ? AND TYPE = 'TABLE'"

          cursor = @connection.parse(sql)
          cursor.bind_param(1, @table)
          cursor.exec

          @dependencies = []
          while row = cursor.fetch_hash
            @dependencies << row
          end
        rescue => e
          raise "Error retrieving dependencies: #{e.message}"
        ensure
          cursor.close if cursor
        end
      end

      def format_constraint_type(constraint)
        case constraint['CONSTRAINT_TYPE']
        when 'P' then 'Primary Key'
        when 'R' then 'Foreign Key'
        when 'U' then 'Unique'
        when 'C' then 'Check'
        else constraint['CONSTRAINT_TYPE']
        end
      end

      def get_constraint_column_name(constraint)
        constraint['COLUMN_NAME']
      end

      def get_constraint_text(constraint)
        constraint['SEARCH_CONDITION']
      end

      def is_string_type?(column)
        column.data_type.to_s.downcase =~ /(char|varchar|varchar2|clob)/
      end

      def is_date_type?(column)
        column.data_type.to_s.downcase =~ /(date|timestamp)/
      end

      def is_text_type?(column)
        column.data_type.to_s.downcase =~ /(varchar|char|clob)/
      end

      def get_column_size(column)
        column.data_size
      end

      def build_full_text_index_sql(column)
        "CREATE INDEX idx_#{@table.downcase}_#{column.name.downcase}_text ON #{@table.upcase} (#{column.name.upcase}) INDEXTYPE IS CTXSYS.CONTEXT"
      end

      def get_full_text_index_type
        "Oracle Text Index"
      end

      def find_fk_table(fk)
        # Oracle-specific logic for finding referenced table
        fk.gsub(/_id$/i, '').pluralize rescue "#{fk.gsub(/_id$/i, '')}s"
      end

      def disconnect
        @connection.logoff if @connection
      end
    end

    # Oracle column info wrapper
    class OracleColumnInfo
      attr_reader :name, :data_type, :data_size, :precision, :scale, :nullable

      def initialize(row)
        @name = row['COLUMN_NAME']
        @data_type = row['DATA_TYPE']
        @data_size = row['DATA_LENGTH']
        @precision = row['DATA_PRECISION']
        @scale = row['DATA_SCALE']
        @nullable = row['NULLABLE'] == 'Y'
      end

      def nullable?
        @nullable
      end
    end
  end
end
