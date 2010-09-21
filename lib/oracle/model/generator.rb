require 'oci8'

module Oracle
  module Model
    class Generator
      VERSION = '0.1.0'

      attr_reader :connection
      attr_reader :constraints
      attr_reader :foreign_keys
      attr_reader :belongs_to
      attr_reader :table
      attr_reader :view

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
        @belongs_to   = []
        @table        = nil
      end

      def generate(table, view = false)
        @table = table
        @view  = view
        get_constraints(table) unless view
        get_foreign_keys unless view
      end

      private

      # Get the primary key. If there is more than one, then an array of
      # keys are returned.
      #
      def get_primary_keys
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

      def get_foreign_keys
        @constraints.each{ |hash|
          if hash['CONSTRAINT_TYPE'] == 'R'
            @foreign_keys << hash['R_CONSTRAINT_NAME']
          end
        }

        get_belongs_to()
      end

      def get_belongs_to
        @foreign_keys.each{ |fk|
          @belongs_to << find_fk_table(fk)
        }
      end

      def find_fk_table(fk)
        sql = %Q{
          select table_name
          from all_constraints
          where constraint_name = '#{fk}'
        }

        begin
          cursor = @connection.exec(sql)
          fk = cursor.fetch.first
        ensure
          cursor.close
        end

        fk
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
