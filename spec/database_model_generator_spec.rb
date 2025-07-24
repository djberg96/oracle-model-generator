require 'spec_helper'
require 'support/database_connection'

RSpec.describe 'Database Model Generator' do
  include_context 'Database connection'

  describe 'class information' do
    it 'has the correct version number' do
      expect(DatabaseModel::Generator::VERSION).to eq('0.6.0')
    end
  end

  describe '#initialize' do
    it 'accepts a database connection object' do
      expect(generator).to be_a(DatabaseModel::Generator::Base)
      expect(generator.connection).not_to be_nil
    end

    it 'sets up instance variables correctly' do
      expect(generator.constraints).to eq([])
      expect(generator.primary_keys).to eq([])
      expect(generator.foreign_keys).to eq([])
      expect(generator.dependencies).to eq([])
      expect(generator.belongs_to).to eq([])
      expect(generator.polymorphic_associations).to eq([])
      expect(generator.enum_columns).to eq([])
      expect(generator.column_info).to eq([])
      expect(generator.table).to be_nil
      expect(generator.model).to be_nil
    end
  end

  describe '#generate' do
    it 'responds to the generate method' do
      expect(generator).to respond_to(:generate)
    end

    it 'works with a table name' do
      expect { generator.generate('test_employees') }.not_to raise_error
    end

    it 'works with a view name' do
      expect { generator.generate('test_employee_view', true) }.not_to raise_error
    end

    context 'when generating from a table' do
      before { generator.generate('test_employees') }

      it 'sets the table name' do
        # Different databases handle case differently
        expect(generator.table.downcase).to eq('test_employees')
      end

      it 'generates a model name from the table name' do
        expect(generator.model).to eq('TestEmployee')
      end

      it 'sets view to false' do
        expect(generator.view).to be false
      end

      it 'populates column information' do
        expect(generator.column_info).to be_an(Array)
        expect(generator.column_info).not_to be_empty
      end

      it 'finds primary keys' do
        expect(generator.primary_keys).to be_an(Array)
        expect(generator.primary_keys.length).to be > 0
        # Primary key should be employee_id (case may vary by database)
        pk_names = generator.primary_keys.map(&:downcase)
        expect(pk_names).to include('employee_id')
      end

      it 'populates constraints information' do
        expect(generator.constraints).to be_an(Array)
        expect(generator.constraints).not_to be_empty
      end

      it 'detects enum columns' do
        expect(generator.enum_columns).to be_an(Array)
        # Should detect the status column as an enum
        enum_names = generator.enum_columns.map { |e| e[:column_name] }
        expect(enum_names).to include('status')
      end
    end

    context 'when generating from a view' do
      before { generator.generate('test_employee_view', true) }

      it 'sets the table name' do
        expect(generator.table.downcase).to eq('test_employee_view')
      end

      it 'generates the correct model name' do
        expect(generator.model).to eq('TestEmployeeView')
      end

      it 'sets view to true' do
        expect(generator.view).to be true
      end
    end
  end

  describe '#model' do
    it 'returns the active record model name' do
      generator.generate('test_employee_view', true)
      expect(generator).to respond_to(:model)
      expect(generator.model).to eq('TestEmployeeView')
    end

    it 'removes trailing s from model names' do
      generator.generate('test_employees')
      expect(generator.model).to eq('TestEmployee')
    end
  end

  describe '#table' do
    it 'returns the table name' do
      generator.generate('test_employee_view', true)
      expect(generator).to respond_to(:table)
      expect(generator.table.downcase).to eq('test_employee_view')
    end
  end

  describe '#primary_keys' do
    it 'returns an array of primary keys' do
      generator.generate('test_employees')
      expect(generator.primary_keys).to be_an(Array)
      pk_names = generator.primary_keys.map(&:downcase)
      expect(pk_names).to include('employee_id')
    end
  end

  describe '#column_info' do
    it 'returns an array of column metadata' do
      generator.generate('test_employees')
      expect(generator.column_info).to be_an(Array)
      expect(generator.column_info.length).to be > 0

      # Should have at least the columns we created
      column_names = generator.column_info.map { |c| c.name.downcase }
      expect(column_names).to include('employee_id', 'first_name', 'last_name', 'email')
    end
  end

  describe '#constraints' do
    it 'returns an array of constraint information' do
      generator.generate('test_employees')
      expect(generator.constraints).to be_an(Array)
      expect(generator.constraints).not_to be_empty
    end
  end

  describe '#foreign_keys' do
    it 'returns an array of foreign key names' do
      generator.generate('test_employees')
      expect(generator.foreign_keys).to be_an(Array)
      # Our test table doesn't have foreign keys, so this might be empty
    end
  end

  describe '#belongs_to' do
    it 'returns an array of parent tables' do
      generator.generate('test_employees')
      expect(generator.belongs_to).to be_an(Array)
      # Our test table doesn't have foreign keys, so this might be empty
    end
  end

  describe '#dependencies' do
    it 'returns an array of dependent objects' do
      generator.generate('test_employees')
      expect(generator).to respond_to(:dependencies)
      expect(generator.dependencies).to be_an(Array)
    end
  end

  describe '#view' do
    it 'correctly identifies tables vs views' do
      generator.generate('test_employees')
      expect(generator.view).to be false

      generator.generate('test_employee_view', true)
      expect(generator.view).to be true
    end
  end

  describe '#polymorphic_associations' do
    it 'returns an array of polymorphic associations' do
      generator.generate('test_employees')
      expect(generator.polymorphic_associations).to be_an(Array)
      # Our test table doesn't have polymorphic associations
    end
  end

  describe '#enum_columns' do
    it 'returns an array of enum column information' do
      generator.generate('test_employees')
      expect(generator.enum_columns).to be_an(Array)

      # Should detect the status column
      if generator.enum_columns.any?
        status_enum = generator.enum_columns.find { |e| e[:column_name] == 'status' }
        expect(status_enum).not_to be_nil
        expect(status_enum[:values]).to include('active', 'inactive', 'pending')
      end
    end
  end

  describe 'database-specific behavior' do
    it 'handles database-specific data types correctly' do
      generator.generate('test_employees')
      expect(generator.column_info).not_to be_empty

      # Each column should have proper type information
      generator.column_info.each do |col|
        expect(col).to respond_to(:name)
        expect(col.name).to be_a(String)
        expect(col.name).not_to be_empty
      end
    end
  end
end
