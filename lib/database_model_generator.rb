begin
  require 'oci8'
rescue LoadError
  # OCI8 not available - Oracle support will be disabled
end

begin
  require 'tiny_tds'
rescue LoadError
  # TinyTDS not available - SQL Server support will be disabled
end

module DatabaseModel
  module Generator
    # The version of the database-model-generator library
    VERSION = '0.6.0'

    # Factory method to create the appropriate generator based on connection type
    def self.new(connection, options = {})
      database_type = detect_database_type(connection, options)

      case database_type
      when :oracle
        require_relative 'oracle/model/generator'
        Oracle::Model::Generator.new(connection)
      when :sqlserver
        require_relative 'sqlserver/model/generator'
        SqlServer::Model::Generator.new(connection)
      else
        raise ArgumentError, "Unsupported database type: #{database_type}"
      end
    end

    private

    def self.detect_database_type(connection, options = {})
      return options[:type].to_sym if options[:type]

      case connection.class.name
      when 'OCI8'
        :oracle
      when 'TinyTds::Client'
        :sqlserver
      else
        raise ArgumentError, "Cannot detect database type from connection: #{connection.class}"
      end
    end
  end
end

# Base generator class with common functionality
module DatabaseModel
  module Generator
    class Base
      attr_reader :connection, :constraints, :foreign_keys, :belongs_to
      attr_reader :table, :model, :view, :dependencies, :column_info, :primary_keys
      attr_reader :polymorphic_associations

      def initialize(connection)
        raise ArgumentError, "Connection cannot be nil" if connection.nil?
        validate_connection(connection)

        @connection   = connection
        @constraints  = []
        @primary_keys = []
        @foreign_keys = []
        @dependencies = []
        @belongs_to   = []
        @polymorphic_associations = []
        @column_info  = []
        @table        = nil
        @model        = nil
      end

      def generate(table, view = false)
        raise ArgumentError, "Table name cannot be nil or empty" if table.nil? || table.strip.empty?

        @table = normalize_table_name(table)
        @model = generate_model_name(table)
        @view  = view

        reset_state
        get_column_info
        get_primary_keys
        get_foreign_keys unless view
        get_belongs_to
        get_polymorphic_associations unless view
        get_constraints unless view
        get_dependencies unless view

        self
      end

      def generated?
        !@table.nil? && !@column_info.empty?
      end

      def column_names
        return [] unless generated?
        @column_info.map(&:name)
      end

      def table_exists?
        return false unless @table
        check_table_exists(@table)
      end

      def disconnect
        # Default implementation - subclasses should override
        @connection = nil
      end

      def constraint_summary
        return {} unless generated?

        summary = Hash.new { |h, k| h[k] = [] }
        @constraints.each do |constraint|
          type = format_constraint_type(constraint)
          column_name = get_constraint_column_name(constraint)
          summary[column_name.downcase] << type
        end
        summary
      end

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

        build_foreign_key_recommendations(recommendations)
        build_unique_constraint_recommendations(recommendations)
        build_date_recommendations(recommendations)
        build_status_recommendations(recommendations)
        build_composite_recommendations(recommendations)
        build_full_text_recommendations(recommendations)

        recommendations
      end

      private

      # Abstract methods to be implemented by database-specific subclasses
      def validate_connection(connection)
        raise NotImplementedError, "Subclasses must implement validate_connection"
      end

      def normalize_table_name(table)
        raise NotImplementedError, "Subclasses must implement normalize_table_name"
      end

      def check_table_exists(table)
        raise NotImplementedError, "Subclasses must implement check_table_exists"
      end

      def get_column_info
        raise NotImplementedError, "Subclasses must implement get_column_info"
      end

      def get_primary_keys
        raise NotImplementedError, "Subclasses must implement get_primary_keys"
      end

      def get_foreign_keys
        raise NotImplementedError, "Subclasses must implement get_foreign_keys"
      end

      def get_constraints
        raise NotImplementedError, "Subclasses must implement get_constraints"
      end

      def get_dependencies
        raise NotImplementedError, "Subclasses must implement get_dependencies"
      end

      def format_constraint_type(constraint)
        raise NotImplementedError, "Subclasses must implement format_constraint_type"
      end

      def get_constraint_column_name(constraint)
        raise NotImplementedError, "Subclasses must implement get_constraint_column_name"
      end

      # Common implementation methods
      def reset_state
        @constraints.clear
        @primary_keys.clear
        @foreign_keys.clear
        @dependencies.clear
        @belongs_to.clear
        @polymorphic_associations.clear
        @column_info.clear
      end

      def generate_model_name(table)
        model = table.dup
        model.downcase!
        model.chop! if model[-1].chr.downcase == 's'
        model.split('_').map(&:capitalize).join
      end

      def get_belongs_to
        @belongs_to = @foreign_keys.map { |fk| find_fk_table(fk) }.compact
      end

      def get_polymorphic_associations
        @polymorphic_associations = detect_polymorphic_associations
      end

      def detect_polymorphic_associations
        polymorphic_assocs = []
        column_names = @column_info.map { |col| col.name.downcase }

        # Look for patterns like: commentable_type + commentable_id
        # or imageable_type + imageable_id, etc.
        type_columns = column_names.select { |name| name.end_with?('_type') }

        type_columns.each do |type_col|
          base_name = type_col.gsub(/_type$/, '')
          id_col = "#{base_name}_id"

          if column_names.include?(id_col)
            # Check if this isn't already a regular foreign key
            unless @foreign_keys.map(&:downcase).include?(id_col)
              polymorphic_assocs << {
                name: base_name,
                foreign_key: id_col,
                foreign_type: type_col,
                association_name: base_name
              }
            end
          end
        end

        polymorphic_assocs
      end

      # Make sure these polymorphic methods are public
      public

      def has_polymorphic_associations?
        !@polymorphic_associations.empty?
      end

      def polymorphic_association_names
        @polymorphic_associations.map { |assoc| assoc[:name] }
      end

      def polymorphic_has_many_suggestions
        # Suggest has_many associations for models that could be polymorphic parents
        suggestions = []
        @polymorphic_associations.each do |assoc|
          # For a 'commentable' polymorphic association, suggest:
          # has_many :comments, as: :commentable, dependent: :destroy
          child_model = pluralize_for_has_many(assoc[:name])
          suggestions << {
            association: "has_many :#{child_model}, as: :#{assoc[:name]}, dependent: :destroy",
            description: "For models that can have #{child_model} (polymorphic)"
          }
        end
        suggestions
      end

      def find_fk_table(fk)
        # Default implementation - may be overridden by subclasses
        fk.gsub(/_id$/i, '').pluralize rescue "#{fk.gsub(/_id$/i, '')}s"
      end

      private

      def pluralize_for_has_many(singular_name)
        # Simple pluralization - can be enhanced
        case singular_name
        when /able$/
          # commentable -> comments, imageable -> images
          base = singular_name.gsub(/able$/, '')
          case base
          when 'comment' then 'comments'
          when 'image' then 'images'
          when 'tag' then 'tags'
          when 'like' then 'likes'
          when 'favorite' then 'favorites'
          else "#{base}s"
          end
        else
          "#{singular_name}s"
        end
      end

      public

      def find_fk_table(fk)
        # Default implementation - may be overridden by subclasses
        fk.gsub(/_id$/i, '').pluralize rescue "#{fk.gsub(/_id$/i, '')}s"
      end

      def build_foreign_key_recommendations(recommendations)
        @belongs_to.each do |table_ref|
          fk_column = "#{table_ref.downcase.gsub(/s$/, '')}_id"
          col = @column_info.find { |c| c.name.downcase == fk_column }
          if col
            recommendations[:foreign_keys] << {
              column: col.name.downcase,
              sql: "add_index :#{@table.downcase}, :#{col.name.downcase}",
              reason: "Foreign key index for #{col.name}"
            }
          end
        end
      end

      def build_unique_constraint_recommendations(recommendations)
        unique_columns = @column_info.select do |col|
          col.name.downcase =~ /(email|username|code|slug|uuid|token)/ ||
          (!col.nullable? && col.name.downcase =~ /(name|title)$/ && is_string_type?(col))
        end

        unique_columns.each do |col|
          recommendations[:unique_constraints] << {
            column: col.name.downcase,
            sql: "add_index :#{@table.downcase}, :#{col.name.downcase}, unique: true",
            reason: "Unique constraint for #{col.name}"
          }
        end
      end

      def build_date_recommendations(recommendations)
        date_columns = @column_info.select do |col|
          is_date_type?(col) ||
          col.name.downcase =~ /(created_at|updated_at|modified_date|start_date|end_date|due_date)/
        end

        date_columns.each do |col|
          recommendations[:date_queries] << {
            column: col.name.downcase,
            sql: "add_index :#{@table.downcase}, :#{col.name.downcase}",
            reason: "Date queries for #{col.name}"
          }
        end
      end

      def build_status_recommendations(recommendations)
        status_columns = @column_info.select do |col|
          col.name.downcase =~ /(status|state|type|role|priority|level|category)$/ &&
          is_string_type?(col)
        end

        status_columns.each do |col|
          recommendations[:status_enum] << {
            column: col.name.downcase,
            sql: "add_index :#{@table.downcase}, :#{col.name.downcase}",
            reason: "Status/enum queries for #{col.name}"
          }
        end
      end

      def build_composite_recommendations(recommendations)
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
      end

      def build_full_text_recommendations(recommendations)
        text_search_columns = @column_info.select do |col|
          is_text_type?(col) &&
          col.name.downcase =~ /(name|title|description|content|text|search)/ &&
          (get_column_size(col).nil? || get_column_size(col) > 50)
        end

        text_search_columns.each do |col|
          recommendations[:full_text] << {
            column: col.name.downcase,
            sql: build_full_text_index_sql(col),
            reason: "Full-text search for #{col.name}",
            type: get_full_text_index_type
          }
        end
      end

      # Abstract helper methods for database-specific type checking
      def is_string_type?(column)
        raise NotImplementedError, "Subclasses must implement is_string_type?"
      end

      def is_date_type?(column)
        raise NotImplementedError, "Subclasses must implement is_date_type?"
      end

      def is_text_type?(column)
        raise NotImplementedError, "Subclasses must implement is_text_type?"
      end

      def get_column_size(column)
        raise NotImplementedError, "Subclasses must implement get_column_size"
      end

      def build_full_text_index_sql(column)
        raise NotImplementedError, "Subclasses must implement build_full_text_index_sql"
      end

      def get_full_text_index_type
        raise NotImplementedError, "Subclasses must implement get_full_text_index_type"
      end
    end
  end
end
