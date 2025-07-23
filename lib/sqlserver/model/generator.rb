require_relative '../../database_model_generator'

begin
  require 'tiny_tds'
rescue LoadError
  # TinyTds not available - SQL Server support will be disabled
end

module SqlServer
  module Model
    class Generator < DatabaseModel::Generator::Base
      VERSION = DatabaseModel::Generator::VERSION

      private

      def validate_connection(connection)
        unless defined?(TinyTds) && connection.is_a?(TinyTds::Client)
          raise ArgumentError, "Connection must be a TinyTds::Client object. Install 'tiny_tds' gem for SQL Server support."
        end
      end

      def normalize_table_name(table)
        table # SQL Server table names are case-sensitive, preserve as-is
      end

      def check_table_exists(table)
        begin
          sql = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ?"
          result = @connection.execute(sql, table)
          row = result.first
          row && row.values.first > 0
        rescue => e
          puts "Error checking table existence: #{e.message}"
          false
        ensure
          result.cancel if result
        end
      end

      def get_column_info
        begin
          sql = <<~SQL
            SELECT
              COLUMN_NAME,
              DATA_TYPE,
              CHARACTER_MAXIMUM_LENGTH,
              NUMERIC_PRECISION,
              NUMERIC_SCALE,
              IS_NULLABLE,
              COLUMN_DEFAULT
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = ?
            ORDER BY ORDINAL_POSITION
          SQL

          result = @connection.execute(sql, @table)
          @column_info = []

          result.each do |row|
            @column_info << SqlServerColumnInfo.new(row)
          end
        rescue => e
          raise "Error retrieving column information: #{e.message}"
        ensure
          result.cancel if result
        end
      end

      def get_primary_keys
        begin
          sql = <<~SQL
            SELECT c.COLUMN_NAME
            FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
            JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu ON tc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
            JOIN INFORMATION_SCHEMA.COLUMNS c ON ccu.COLUMN_NAME = c.COLUMN_NAME AND ccu.TABLE_NAME = c.TABLE_NAME
            WHERE tc.TABLE_NAME = ? AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
            ORDER BY c.ORDINAL_POSITION
          SQL

          result = @connection.execute(sql, @table)
          @primary_keys = []

          result.each do |row|
            @primary_keys << row['COLUMN_NAME']
          end
        rescue => e
          raise "Error retrieving primary keys: #{e.message}"
        ensure
          result.cancel if result
        end
      end

      def get_foreign_keys
        begin
          sql = <<~SQL
            SELECT ccu.COLUMN_NAME
            FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
            JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu ON tc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
            WHERE tc.TABLE_NAME = ? AND tc.CONSTRAINT_TYPE = 'FOREIGN KEY'
          SQL

          result = @connection.execute(sql, @table)
          @foreign_keys = []

          result.each do |row|
            @foreign_keys << row['COLUMN_NAME']
          end
        rescue => e
          raise "Error retrieving foreign keys: #{e.message}"
        ensure
          result.cancel if result
        end
      end

      def get_constraints
        begin
          sql = <<~SQL
            SELECT
              tc.CONSTRAINT_NAME,
              tc.CONSTRAINT_TYPE,
              ccu.COLUMN_NAME,
              cc.CHECK_CLAUSE
            FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
            LEFT JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu ON tc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
            LEFT JOIN INFORMATION_SCHEMA.CHECK_CONSTRAINTS cc ON tc.CONSTRAINT_NAME = cc.CONSTRAINT_NAME
            WHERE tc.TABLE_NAME = ?
          SQL

          result = @connection.execute(sql, @table)
          @constraints = []

          result.each do |row|
            @constraints << {
              'CONSTRAINT_NAME' => row['CONSTRAINT_NAME'],
              'CONSTRAINT_TYPE' => row['CONSTRAINT_TYPE'],
              'COLUMN_NAME' => row['COLUMN_NAME'],
              'CHECK_CLAUSE' => row['CHECK_CLAUSE']
            }
          end
        rescue => e
          raise "Error retrieving constraints: #{e.message}"
        ensure
          result.cancel if result
        end
      end

      def get_dependencies
        begin
          sql = <<~SQL
            SELECT
              OBJECT_NAME(referencing_id) AS NAME,
              'TABLE' AS TYPE
            FROM sys.sql_expression_dependencies sed
            JOIN sys.objects o ON sed.referenced_id = o.object_id
            WHERE o.name = ? AND o.type = 'U'
          SQL

          result = @connection.execute(sql, @table)
          @dependencies = []

          result.each do |row|
            @dependencies << {
              'NAME' => row['NAME'],
              'TYPE' => row['TYPE']
            }
          end
        rescue => e
          # Dependencies query may fail on some SQL Server versions, continue without error
          @dependencies = []
        ensure
          result.cancel if result
        end
      end

      def format_constraint_type(constraint)
        case constraint['CONSTRAINT_TYPE']
        when 'PRIMARY KEY' then 'Primary Key'
        when 'FOREIGN KEY' then 'Foreign Key'
        when 'UNIQUE' then 'Unique'
        when 'CHECK' then 'Check'
        else constraint['CONSTRAINT_TYPE']
        end
      end

      def get_constraint_column_name(constraint)
        constraint['COLUMN_NAME']
      end

      def is_string_type?(column)
        column.data_type.downcase =~ /(char|varchar|nchar|nvarchar|text|ntext)/
      end

      def is_date_type?(column)
        column.data_type.downcase =~ /(date|time|datetime|datetime2|smalldatetime|datetimeoffset)/
      end

      def is_text_type?(column)
        column.data_type.downcase =~ /(varchar|nvarchar|char|nchar|text|ntext)/
      end

      def get_column_size(column)
        column.character_maximum_length
      end

      def build_full_text_index_sql(column)
        "CREATE FULLTEXT INDEX ON #{@table} (#{column.name.upcase}) KEY INDEX PK_#{@table}"
      end

      def get_full_text_index_type
        "SQL Server Full-Text Index"
      end

      def find_fk_table(fk)
        # SQL Server-specific logic for finding referenced table
        # Try to get actual referenced table from foreign key constraints
        begin
          sql = <<~SQL
            SELECT
              OBJECT_NAME(f.referenced_object_id) AS referenced_table
            FROM sys.foreign_keys f
            JOIN sys.foreign_key_columns fc ON f.object_id = fc.constraint_object_id
            JOIN sys.columns c ON fc.parent_object_id = c.object_id AND fc.parent_column_id = c.column_id
            WHERE f.parent_object_id = OBJECT_ID(?) AND c.name = ?
          SQL

          result = @connection.execute(sql, @table, fk)
          row = result.first
          if row && row['referenced_table']
            return row['referenced_table'].downcase
          end
        rescue => e
          # Fall back to naming convention if query fails
        end

        # Fallback to naming convention
        fk.gsub(/_id$/i, '').pluralize rescue "#{fk.gsub(/_id$/i, '')}s"
      end

      def disconnect
        @connection.close if @connection
      end
    end

    # SQL Server column info wrapper
    class SqlServerColumnInfo
      attr_reader :name, :data_type, :character_maximum_length, :numeric_precision, :numeric_scale, :nullable, :column_default

      def initialize(row)
        @name = row['COLUMN_NAME']
        @data_type = row['DATA_TYPE']
        @character_maximum_length = row['CHARACTER_MAXIMUM_LENGTH']
        @numeric_precision = row['NUMERIC_PRECISION']
        @numeric_scale = row['NUMERIC_SCALE']
        @nullable = row['IS_NULLABLE'] == 'YES'
        @column_default = row['COLUMN_DEFAULT']
      end

      def nullable?
        @nullable
      end

      def data_size
        @character_maximum_length
      end

      def precision
        @numeric_precision
      end

      def scale
        @numeric_scale
      end
    end
  end
end
