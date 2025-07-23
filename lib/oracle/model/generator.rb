require 'oci8'

module Oracle
  module Model
    class Generator
      # The version of the oracle-model-generator library
      VERSION = '0.5.0'

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
        raise ArgumentError, "Connection cannot be nil" if connection.nil?
        raise ArgumentError, "Connection must be an OCI8 object" unless connection.is_a?(OCI8)

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
        raise ArgumentError, "Table name cannot be nil or empty" if table.nil? || table.strip.empty?

        @table = table.upcase
        @model = generate_model_name(table)
        @view  = view

        begin
          unless view
            get_constraints
            get_foreign_keys
            get_column_info
          end

          get_primary_keys
          get_dependencies
        rescue => e
          # Reset state on error to ensure object is in a consistent state
          reset_state
          raise "Failed to generate model for table '#{table}': #{e.message}"
        end
      end

      # Public method to check if the generator has been populated with data
      def generated?
        !@table.nil? && !@model.nil?
      end

      # Public method to get column names
      def column_names
        @column_info.map(&:name).map(&:downcase)
      end

      # Public method to check if table/view exists
      def table_exists?
        return false unless @table

        sql = @view ? "SELECT 1 FROM all_views WHERE view_name = '#{@table}'" :
                     "SELECT 1 FROM all_tables WHERE table_name = '#{@table}'"

        cursor = nil
        begin
          cursor = @connection.exec(sql)
          !cursor.fetch.nil?
        rescue
          false
        ensure
          cursor.close if cursor
        end
      end

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

      # Public method to get index recommendations for performance optimization
      def index_recommendations
        return {} unless generated?

        recommendations = {
          foreign_keys: [],
          unique_constraints: [],
          date_queries: [],
          status_enum: [],
          composite: [],
          full_text: []
        }

        # Foreign key indexes
        @belongs_to.each do |table|
          fk_column = "#{table.downcase.gsub(/s$/, '')}_id"
          col = @column_info.find { |c| c.name.downcase == fk_column }
          if col
            recommendations[:foreign_keys] << {
              column: col.name.downcase,
              sql: "add_index :#{@table.downcase}, :#{col.name.downcase}",
              reason: "Foreign key index for #{col.name}"
            }
          end
        end

        # Unique constraint indexes
        unique_columns = @column_info.select do |col|
          col.name.downcase =~ /(email|username|code|slug|uuid|token)/ ||
          (!col.nullable? && col.name.downcase =~ /(name|title)$/ && col.data_type.to_s =~ /varchar/i)
        end

        unique_columns.each do |col|
          recommendations[:unique_constraints] << {
            column: col.name.downcase,
            sql: "add_index :#{@table.downcase}, :#{col.name.downcase}, unique: true",
            reason: "Unique constraint for #{col.name}"
          }
        end

        # Date/timestamp indexes
        date_columns = @column_info.select do |col|
          col.data_type.to_s.downcase =~ /(date|timestamp)/ ||
          col.name.downcase =~ /(created_at|updated_at|modified_date|start_date|end_date|due_date)/
        end

        date_columns.each do |col|
          recommendations[:date_queries] << {
            column: col.name.downcase,
            sql: "add_index :#{@table.downcase}, :#{col.name.downcase}",
            reason: "Date queries for #{col.name}"
          }
        end

        # Status/enum column indexes
        status_columns = @column_info.select do |col|
          col.name.downcase =~ /(status|state|type|role|priority|level|category)$/ &&
          col.data_type.to_s =~ /(varchar|char)/i
        end

        status_columns.each do |col|
          recommendations[:status_enum] << {
            column: col.name.downcase,
            sql: "add_index :#{@table.downcase}, :#{col.name.downcase}",
            reason: "Status/enum queries for #{col.name}"
          }
        end

        # Composite indexes for common query patterns
        foreign_key_columns = recommendations[:foreign_keys].map { |fk| fk[:column] }
        date_column_names = recommendations[:date_queries].map { |d| d[:column] }
        status_column_names = recommendations[:status_enum].map { |s| s[:column] }

        if foreign_key_columns.any? && date_column_names.any?
          fk_col = foreign_key_columns.first
          date_col = date_column_names.find { |col| col =~ /created/ } || date_column_names.first
          recommendations[:composite] << {
            columns: [fk_col, date_col],
            sql: "add_index :#{@table.downcase}, [:#{fk_col}, :#{date_col}]",
            reason: "Composite index for filtering by #{fk_col} and #{date_col}"
          }
        end

        if status_column_names.any? && date_column_names.any?
          status_col = status_column_names.first
          date_col = date_column_names.find { |col| col =~ /created/ } || date_column_names.first
          recommendations[:composite] << {
            columns: [status_col, date_col],
            sql: "add_index :#{@table.downcase}, [:#{status_col}, :#{date_col}]",
            reason: "Composite index for filtering by #{status_col} and #{date_col}"
          }
        end

        # Full-text search indexes
        text_search_columns = @column_info.select do |col|
          col.data_type.to_s.downcase =~ /(varchar|char|clob)/ &&
          col.name.downcase =~ /(name|title|description|content|text|search)/ &&
          (col.data_size.nil? || col.data_size > 50)
        end

        text_search_columns.each do |col|
          recommendations[:full_text] << {
            column: col.name.downcase,
            sql: "CREATE INDEX idx_#{@table.downcase}_#{col.name.downcase}_text ON #{@table.upcase} (#{col.name.upcase}) INDEXTYPE IS CTXSYS.CONTEXT",
            reason: "Full-text search for #{col.name}",
            type: "Oracle Text Index"
          }
        end

        recommendations
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

      def get_column_info
        begin
          table = @connection.describe_table(@table)
          table.columns.each{ |col| @column_info << col }
        rescue => e
          raise "Failed to describe table '#{@table}': #{e.message}"
        end
      end

      # Returns an array of primary keys.
      #
      def get_primary_keys
        primary_key_constraints = @constraints.select { |hash| hash['CONSTRAINT_TYPE'] == 'P' }
        @primary_keys = primary_key_constraints
                        .map { |hash| hash['COLUMN_NAME'].downcase }
                        .sort # Ensure consistent ordering
                        .uniq # Remove any duplicates
      end

      # Returns an array of foreign keys.
      #
      def get_foreign_keys
        foreign_key_constraints = @constraints.select { |hash| hash['CONSTRAINT_TYPE'] == 'R' }
        @foreign_keys = foreign_key_constraints
                        .map { |hash| hash['R_CONSTRAINT_NAME'] }
                        .compact
                        .uniq

        get_belongs_to()
      end

      # Returns an array of tables that the current table has foreign key
      # ties to.
      #
      def get_belongs_to
        @belongs_to = @foreign_keys.map { |fk| find_fk_table(fk) }
                                   .compact
                                   .uniq
                                   .sort
      end

      # Find table name based on a foreign key name.
      #
      def find_fk_table(fk)
        sql = %Q{
          select table_name
          from all_constraints
          where constraint_name = '#{fk}'
        }

        cursor = nil
        begin
          cursor = @connection.exec(sql)
          result = cursor.fetch
          result ? result.first : nil
        rescue => e
          raise "Failed to find foreign key table for '#{fk}': #{e.message}"
        ensure
          cursor.close if cursor
        end
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

        cursor = nil
        begin
          cursor = @connection.exec(sql)
          while rec = cursor.fetch_hash
            @constraints << rec
          end
        rescue => e
          raise "Failed to get constraints for table '#{@table}': #{e.message}"
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

        cursor = nil
        begin
          cursor = @connection.exec(sql)
          while rec = cursor.fetch_hash
            @dependencies << rec
          end
        rescue => e
          raise "Failed to get dependencies for table '#{@table}': #{e.message}"
        ensure
          cursor.close if cursor
        end
      end

    end
  end
end
